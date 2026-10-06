ScriptName CS2GameScript Extends Quest

CS2ConfigScript Property Config Auto
Bool Property SexLabInstalled Auto Hidden
Bool Property FlowerGirlsInstalled Auto Hidden
Bool Property ArousedInstalled Auto Hidden
Armor Property CumshotSOS Auto
ArmorAddon CumshotSOSAA
Armor Property CumshotStatic Auto
ArmorAddon CumshotStaticAA
FormList Property ParticlesSOS Auto
FormList Property ParticlesStatic Auto
Armor Property UrethraNodeSOS Auto
Armor Property UrethraNodeStatic Auto
FormList Property CS2UrethraAddons Auto
FormList Property CS2DropsS Auto
FormList Property CS2DropsM Auto
FormList Property CS2DropsL Auto
FormList Property CS2ProjectileSpellsV1 Auto
FormList Property CS2ProjectileSpellsV2 Auto
FormList Property CS2ProjectileSpellsV3 Auto
FormList Property CS2ProjectileSpellsV4 Auto
Activator Property CS2ProjectileLauncher Auto
MiscObject Property CS2Tracer Auto
ObjectReference Property CS2CumPoolMarker Auto
FormList Property CS2EquipableSchlongs Auto
Int Property debugMsgLevel Auto Hidden
Actor Property PlayerRef Auto

Quest SexLab_Quest
Faction SexLab_AnimatingFaction
Quest SAM_Quest
Quest Aroused_Quest
Faction Aroused_Faction
Int ArousedModType  ; 1 = SL, 2 = FG
String FGModName
Armor armorOnSOS
Armor armorOnStatic
String jfile = "Cumshot/AdjustValues"
Int knownSchlongs
Int installedSchlongs
String[] knownSchlongKeys
Faction[] schlongFaction
String[] schlongKey
String[] schlongEsp  ; no longer used
String[] schlongRace
Int knownEqSchlongs
Form[] eqSchlongs
String[] eqSchlongKeys
Int knownSpecialBodies
Form[] specialBodies
String[] specialBodyKeys
Bool[] specialRaceFemale
Int rnd_s1
Int rnd_s2
Int rnd_s3
Spell hybridSpell  ; invisible spurt from "Cumshot - Particles Hybrid.esp", None if that patch is not loaded


; --------------------------------------------------------------------
;                Initialization and data gathering
; --------------------------------------------------------------------

; first-time initialization
Event OnInit()
	Initialize()
	ResetQRand()  ; set the Wichmann-Hill seed values
	DebugMessage("CS2: Initialized (OnInit)")
EndEvent

; called on every game load
Function InitOnLoad()
	Initialize()
	DebugMessage("CS2: Initialized (InitOnLoad)")
EndFunction


Function Initialize()
	CumshotSOSAA = CumshotSOS.GetNthArmorAddon(0)
	CumshotStaticAA = CumshotStatic.GetNthArmorAddon(0)

	; Checking for supported mods being installed
	If Game.GetModByName("SexLab.esm") != 255
		SexLab_Quest = Game.GetFormFromFile(0xD62, "SexLab.esm") as Quest
		SexLab_AnimatingFaction = Game.GetFormFromFile(0xE50F, "SexLab.esm") as Faction
		SexLabInstalled = True
	Else
		SexLabInstalled = False
	EndIf
	;
	If Game.GetModByName("FlowerGirls SE.esm") != 255
		FlowerGirlsInstalled = True
		FGModName = "FlowerGirls SE.esm"
	ElseIf Game.GetModByName("FlowerGirls.esm") != 255
		FlowerGirlsInstalled = True
		FGModName = "FlowerGirls.esm"
	Else
		FlowerGirlsInstalled = False
	EndIf
	;
	If SexLabInstalled && Game.GetModByName("SexLabAroused.esm") != 255
		ArousedInstalled = True
		ArousedModType = 1
		Aroused_Quest = Game.GetFormFromFile(0x4290F, "SexLabAroused.esm") as Quest
		Aroused_Faction = Game.GetFormFromFile(0x3FC36, "SexLabAroused.esm") as Faction
		RegisterForModEvent("CS2UpdateArousal", "UpdateArousal")
	ElseIf FlowerGirlsInstalled && Game.GetModByName("ArousedRedux.esm") != 255
		ArousedInstalled = True
		ArousedModType = 2
		Aroused_Quest = Game.GetFormFromFile(0x4290F, "ArousedRedux.esm") as Quest
		Aroused_Faction = Game.GetFormFromFile(0x3FC36, "ArousedRedux.esm") as Faction
		RegisterForModEvent("CS2UpdateArousal", "UpdateArousal")
	Else
		ArousedInstalled = False
		ArousedModType = 0
	EndIf
	;
	If Game.GetModByName("SAM - Shape Atlas for Men.esp") != 255
		SAM_Quest = Game.GetFormFromFile(0xD62, "SAM - Shape Atlas for Men.esp") as Quest
	EndIf
	;
	; ESL-flagged, so GetModByName() can't see it; GetFormFromFile() returns None when it is absent
	hybridSpell = Game.GetFormFromFile(0x802, "Cumshot - Particles Hybrid.esp") as Spell

	Config.Initialize()
	BuildEquipableSchlongList()
	BuildSpecialBodiesList()
	SelectArmorToEquip(Config.ejaculationMode)
EndFunction


; Select armor objects to be equipped for different modes.
; Called on initialization, and from MCM when ejaculation mode has been changed.
Function SelectArmorToEquip(Int mode)
	If mode == 1  ; animated mesh
		armorOnSOS = CumshotSOS
		armorOnStatic = CumshotStatic
	ElseIf mode == 2  ; particles - set to an average cum amount for now
		armorOnSOS = ParticlesSOS.GetAt(4) as Armor
		armorOnStatic = ParticlesStatic.GetAt(4) as Armor
	Else
		armorOnSOS = UrethraNodeSOS
		armorOnStatic = UrethraNodeStatic
	EndIf
EndFunction


; Builds a list of installed SOS schlong types
Function BuildSchlongList()
	knownSchlongs = JsonUtil.PathCount(jfile, ".SOSAddons")
	knownSchlongKeys = JsonUtil.PathMembers(jfile, ".SOSAddons")
	installedSchlongs = 0
	schlongKey = new String[100]
	schlongRace = new String[100]
	schlongFaction = new Faction[100]
	String addonKey
	String addonEsp
	String addonRace
	Int atSign
	Int i = knownSchlongs - 1  ; reverse order - because JsonUtil.PathMembers() sorts keys by name, and racial variants have to be scanned before the generic entry
	While i >= 0
		addonKey = knownSchlongKeys[i]
		atSign = StringUtil.Find(addonKey, "@")
		If atSign == -1  ; no At - entry is just the esp name, valid for all races
			addonRace = "DFLT"
		Else  ; entry has an At sign with the name of a race after it - for race-specific schlong variants
			addonRace = StringUtil.Substring(addonKey, atSign + 1)
		EndIf
		addonEsp = JsonUtil.GetPathStringValue(jfile, ".SOSAddons." + addonKey)
		addonEsp = StringUtil.Substring(addonEsp, StringUtil.Find(addonEsp, "|") + 1)
		If Game.GetModByName(addonEsp) != 255  ; the SOS addon esp is installed and active
			schlongKey[installedSchlongs] = addonKey
			schlongRace[installedSchlongs] = addonRace
			schlongFaction[installedSchlongs] = JsonUtil.GetPathFormValue(jfile, ".SOSAddons." + addonKey) as Faction
			DebugMessage("CS2: Schlong addon found: " + addonEsp + " for Race " + addonRace, False)
			installedSchlongs += 1
		EndIf
		i -= 1
	EndWhile
	DebugMessage("CS2: SOS Schlong list built", False)
EndFunction


; Reads a list of known equipable schlong types from the json file
Function BuildEquipableSchlongList()
	CS2EquipableSchlongs.Revert()  ; clear the form list
	knownEqSchlongs = JsonUtil.PathCount(jfile, ".EquipObjects")
	eqSchlongKeys = JsonUtil.PathMembers(jfile, ".EquipObjects")
	eqSchlongs = new Form[100]
	Int i = 0
	While i < knownEqSchlongs
		eqSchlongs[i] = JsonUtil.GetPathFormValue(jfile, ".EquipObjects." + eqSchlongKeys[i])
		CS2EquipableSchlongs.AddForm(eqSchlongs[i])  ; add the schlongs to a form list so we can quickly check if any of them is equipped
		i += 1
	EndWhile
	DebugMessage("CS2: " + knownEqSchlongs + " equipable schlong types read.", False)
EndFunction


; Builds a list of ActorBases and races that have a penis firmly attached to their body
; Their skeleton must have the Genitals06 node, it's meant to be used for humanoid characters
Function BuildSpecialBodiesList()
	knownSpecialBodies = JsonUtil.PathCount(jfile, ".SpecialBodies")
	specialBodyKeys = JsonUtil.PathMembers(jfile, ".SpecialBodies")
	specialBodies = new Form[100]
	specialRaceFemale = new Bool[100]
	Int i = 0
	While i < knownSpecialBodies
		specialBodies[i] = JsonUtil.GetPathFormValue(jfile, ".SpecialBodies." + specialBodyKeys[i])
		specialRaceFemale[i] = (StringUtil.Find(specialBodyKeys[i], "@f") >= 0)  ; Find() returns -1 if no "@f" is found in the key
		i += 1
	EndWhile
	DebugMessage("CS2: " + knownSpecialBodies + " special body types read.", False)
EndFunction


; --------------------------------------------------------------------
;                       Manual event triggering
; --------------------------------------------------------------------

; handle Trigger Ejaculation and Reload JSON hotkeys
Event OnKeyDown(Int keyCode)
	If Utility.IsInMenuMode() || UI.IsMenuOpen("Console") || UI.IsMenuOpen("Loading Menu")
		Return
	EndIf
	
	If keyCode == Config.triggerKey
		Actor target = PlayerRef
		If Input.IsKeyPressed(42) || Input.IsKeyPressed(54)  ; Shift keys
			Actor crosshairTarget = Config.GetValidCrosshairRef()
			If crosshairTarget != none
				target = crosshairTarget
			Else
				Return
			EndIf
		EndIf

		If StorageUtil.HasFormValue(target, "CS2_ejaculating")
			DebugMessage(target.GetLeveledActorBase().GetName() + ": Ejaculation stopped manually")
			RemoveCumshot(target)
		Else
			DebugMessage(target.GetLeveledActorBase().GetName() + ": Ejaculation triggered manually")
			Ejaculate(target)
			StorageUtil.SetFloatValue(target, "CS2_LastOrgasmTime", Utility.GetCurrentGameTime())
			If Config.hotkeyExposure > 0
				ArousedSimulateOrgasm(target, -Config.hotkeyExposure)
			EndIf
		EndIf

	ElseIf keyCode == Config.reloadJsonKey
		JsonUtil.Unload(jfile, saveChanges = False)
		JsonUtil.Load(jfile)
		DebugMessage("AdjustValues.json reloaded.")
	EndIf
EndEvent


; --------------------------------------------------------------------
;                       Displaying ejaculations
; --------------------------------------------------------------------

; Shows a visible ejaculation on an actor. Four different modes / technical implementations:
; 1) Animated mesh - an animated armor mesh is equipped on the actor, as in SL Cumshot 1.x
; 2) Particles - similar to 1, but the equipped armor is a particle emitter
; 3) Drop objects - launches multiple cum drop objects per spurt
; 4) Projectiles - casts a series of spells with cum spurt projectiles
Function Ejaculate(Actor a)
	Int mode = Config.ejaculationMode
	Int bodyClass = Config.maleBodyClass
	ActorBase aBase = a.GetLeveledActorBase()
	Bool isFemale = (aBase.GetSex() == 1)
	Float aWeight = aBase.GetWeight()
	String aRace = a.GetRace().GetName()
	String aName = aBase.GetName() 
	Bool useStatic = False
	Armor armorToEquip = armorOnSOS
	String transformKey
	Float[] move = new Float[3]
	Float[] move0 = new Float[3]
	Float[] move100 = new Float[3]
	Float[] rotate = new Float[3]
	Float particlesEjacTime = 5.0
	Int pIndex = 0
	Float equipTime


	; still ejaculating from a previous call - abort this
	If StorageUtil.HasFormValue(a, "CS2_ejaculating")
		Return
	EndIf

	; Checks if the actor has an equipable schlong or SOS addon, or a special body with included penis.
	; Equipable schlongs and SOS addons take priority because they can replace the included penis.
	Int specialBody = 0
	Int equipableSchlong = HasSchlongItem(a)
	If equipableSchlong == 0
		specialBody = HasSpecialBody(a, isFemale)
		If (isFemale || !Config.genMalesAlways) && specialBody == 0
			; plain, non-futa female. Cumshot doesn't handle those abominations :P
			DebugMessage(aName + " does not have a genital that allows them to ejaculate. No cumshot.")
			Return
		EndIf
	EndIf

	; Send an event calling GetActorArousal(a) in the respective Aroused version
	; to update the actor's sla_Aroused faction value, which will be read later.
	; Why do it this way, instead of simply calling GetActorArousal(a) when it's needed?
	; While the function usually returns instantly as expected, occasionally it will take 20 or more seconds to complete,
	; stalling the Ejaculate function until the scene is over, at least in Flower Girls scenes.
	; So we need to call GetActorArousal asynchronously in a separate Papyrus thread,
	; and hope it will have updated sla_Aroused by the time it's being read (via GetCumAmount or GetEjaculationPower).
	; Worst that can happen is that an outdated arousal value is read, instead of seeing no cumshot at all.
	If Config.useArousal
		Int handle = ModEvent.Create("CS2UpdateArousal")
		If handle
			ModEvent.PushForm(handle, a)
			ModEvent.Send(handle)
		EndIf
	EndIf

	; get position and rotation adjustments from AdjustValues.json, according to body / schlong type
	If equipableSchlong > 0
		transformKey = eqSchlongKeys[equipableSchlong - 1]
	ElseIf specialBody > 0
		transformKey = specialBodyKeys[specialBody - 1]
	ElseIf bodyClass == 0  ; esp-less body replacers
		transformKey = Config.maleBodyName
		If transformKey == "SAM Light"
			If JsonUtil.StringListHas(jfile, "SAM Races", aRace)
				transformKey = "SAM " + aRace
			EndIf
		Else
			useStatic = True
			armorToEquip = armorOnStatic
			If JsonUtil.StringListHas(jfile, "Static Races", aRace)
				transformKey = aRace
			EndIf
		EndIf
	ElseIf bodyClass == 1  ; SOS Full
		transformKey = "SOS Default"  ; if actor is in no known schlong faction
		Int f = 0
		While f < installedSchlongs
			If a.IsInFaction(schlongFaction[f])
				If schlongRace[f] == aRace || schlongRace[f] == "DFLT"
					transformKey = schlongKey[f]
					f = installedSchlongs  ; found, don't scan the list further
				EndIf
			EndIf
			f += 1
		EndWhile
	ElseIf bodyClass == 2  ; SOS Light
		transformKey = Config.maleBodyName
	ElseIf bodyClass == 3  ; SAM
		transformKey = "SAM Default"
		If JsonUtil.StringListHas(jfile, "SAM Races", aRace)
			transformKey = "SAM " + aRace
		EndIf
	EndIf
	DebugMessage(aName + " uses Transform Key: " + transformKey)
	
	JsonUtil.FloatListSlice(jfile, transformKey, move0, 0)  ; get three values at once from the adjustment data
	JsonUtil.FloatListSlice(jfile, transformKey, move100, 3)
	JsonUtil.FloatListSlice(jfile, transformKey, rotate, 6)
	move[0] = move0[0] + (move100[0] - move0[0]) * aWeight / 100.0  ; interpolate between body weight 0 and 100
	move[1] = move0[1] + (move100[1] - move0[1]) * aWeight / 100.0
	move[2] = move0[2] + (move100[2] - move0[2]) * aWeight / 100.0
	If debugMsgLevel > 0  ; extra check avoids concatenating lots of strings if nothing is actually written
		DebugMessage("CS2: " + aName + " (" + aRace + ") (weight " + aWeight + "):", False)
		DebugMessage("     translation: [" + move[0] + " " + move[1] + " " + move[2] + "]   rotation: [" + rotate[0] + " " + rotate[1] + " " + rotate[2] + "]", False)
	EndIf

	If AnimationEnabled()
		; penis pulse: custom slot 0 of the TNG / SOS auxbones graph (file shipped with this mod)
		Debug.SendAnimationEvent(a, "SOSCustom00")
		StorageUtil.SetIntValue(a, "CS2_AnimPlayed", 1)
	EndIf

	Utility.Wait(Config.equipDelay)  ; fixes cumshots failing to show up for some users
	ClampActorValues(a)  ; in case extended range has been turned off, and this actor's values haven't been adjusted yet

	If mode == 2  ; Particles - choose an emitter according to cum amount
		pIndex = (Math.Pow(GetCumAmount(a) + 0.2, 0.65) * 2.0 - 1.5) as Int  ; spread out indexes for high cum amount
		If pIndex < 0
			pIndex = 0
		ElseIf pIndex > 14
			pIndex = 14
		EndIf
		If useStatic
			armorToEquip = ParticlesStatic.GetAt(pIndex) as Armor
		Else
			armorToEquip = ParticlesSOS.GetAt(pIndex) as Armor
		EndIf
		particlesEjacTime = pIndex + 1.5
	EndIf

	a.EquipItem(armorToEquip, abPreventRemoval = True, abSilent = True)  ; don't do AddItem first, it will make NPCs redress
	equipTime = Utility.GetCurrentRealTime()  ; the particle emitter's timeline starts about here
	StorageUtil.SetFormValue(a, "CS2_ejaculating", armorToEquip)

	If a == PlayerRef && Game.GetCameraState() == 3  ; TFC
		a.QueueNiNodeUpdate()  ; fixes cumshot mesh (or helper node) not attaching to the player in TFC mode
		If Config.maleBodyClass == 3 && aBase.GetSex() == 0  ; QueueNiNodeUpdate() resets SAM body textures
		
		EndIf
	EndIf
	
	Utility.Wait(0.05)  ; needed for NiOverride to recognize nodes
	
	; adjust the urethra node according to schlong or body type
	If mode >= 3  ; drop objects, or projectiles
		rotate[2] = rotate[2] + 10.0  ; tilt the helper node 10 degrees up to match the mesh animation angle
	EndIf
	NiOverride.AddNodeTransformPosition(a, False, isFemale, "Urethra", "SLCCumAdjust", move)
	NiOverride.AddNodeTransformRotation(a, False, isFemale, "Urethra", "SLCCumAdjust", rotate)
	NiOverride.UpdateNodeTransform(a, False, isFemale, "Urethra")

	If mode == 1  ; animated mesh: set alpha (opacity) for spurts 1-4 and final drip
		Float spurtsAlpha = GetCumOpacity(a)
		Float dripAlpha = 0.0
		If Config.showDrip
			dripAlpha = spurtsAlpha
		EndIf
		If useStatic
			NiOverride.AddOverrideFloat(a, isFemale, CumshotStatic, CumshotStaticAA, "Tri Cumshot 1", 8, -1, spurtsAlpha, False)
			NiOverride.AddOverrideFloat(a, isFemale, CumshotStatic, CumshotStaticAA, "Tri Cumshot 5", 8, -1, dripAlpha, False)
		Else
			NiOverride.AddOverrideFloat(a, isFemale, CumshotSOS, CumshotSOSAA, "Tri Cumshot 1", 8, -1, spurtsAlpha, False)
			NiOverride.AddOverrideFloat(a, isFemale, CumshotSOS, CumshotSOSAA, "Tri Cumshot 5", 8, -1, dripAlpha, False)
		EndIf
		If Config.tracerObject
			; emit four tracer objects (= num of spurts), then keep the drip hanging for a while
			EmitTracers(a, totalTime = 5.0, timePerObject = 1.25, preTime = 0.0)
			RemoveCumshot(a, waitTime = 4.0)
		Else
			RemoveCumshot(a, waitTime = 9.0)
		EndIf
	ElseIf mode == 2  ; particles
		If HybridEnabled()
			; invisible projectiles under the particle spurts: splash decals and sound, no second stream
			EjaculateHybridProjectiles(a, ParticleSpurtTimes(pIndex), equipTime)
			RemoveCumshot(a, waitTime = particlesEjacTime - (Utility.GetCurrentRealTime() - equipTime))
		ElseIf Config.tracerObject
			EmitTracers(a, totalTime = particlesEjacTime, timePerObject = 1.05, preTime = 0.2)
			RemoveCumshot(a)
		Else
			RemoveCumshot(a, waitTime = particlesEjacTime)
		EndIf
	ElseIf mode == 3  ; drop objects
		EjaculateObjects(a)
		RemoveCumshot(a)
	ElseIf mode == 4  ; spell projectiles
		EjaculateProjectiles(a)
		RemoveCumshot(a)
	EndIf

EndFunction


; Makes an actor ejaculate multiple spurts of cum drop objects.
; Characteristics of the cumshot (cum amount, "shooting power", num of spurts) are influenced by MCM settings and other factors.
Function EjaculateObjects(Actor a)
	Float amount = GetCumAmount(a)
	Float power = GetEjaculationPower(a) * Math.sqrt(amount / 5.0)  ; low total cum amount decreases power
	Float spurtRatio = GetSpurtRatio(a)  ; approximate number of spurts the ejaculation is divided into
	Int alphaVariant = (GetCumOpacity(a) * 10.0 + 0.5) as Int
	Form dropS = CS2DropsS.GetAt(alphaVariant)
	Form dropM = CS2DropsM.GetAt(alphaVariant)
	Form dropL = CS2DropsL.GetAt(alphaVariant)

	ObjectReference proxy = None
	Float spurtAmount
	Float spurtPower
	Float spurtWait = 0.25
	Float amountLeft = amount
	Int spurtNo = 1

	While amountLeft >= 0.25
		spurtAmount = amount / spurtRatio * (0.4 + 0.8 * amountLeft / amount)  ; later spurts tend to have less cum
		spurtAmount *= 0.9 + (spurtWait - 0.25) * 0.5  ; longer pause between two spurts increases cum amount in next spurt
		If spurtNo == 1  ; randomizing, first spurt can be mostly "hot air"
			spurtAmount *= QRand(0.3, 1.2)
		Else
			spurtAmount *= QRand(0.8, 1.2)
		EndIf
		If spurtAmount < 0.25
			spurtAmount = 0.25
		ElseIf spurtAmount > amountLeft
			spurtAmount = amountLeft
		EndIf
		spurtPower = power * Math.sqrt(amountLeft / amount)  ; power sharply drops near the end of ejaculation

		If a.Is3DLoaded()  ; don't try to display spurt if actor is unloaded, may help with drop scripts not finishing
			If Game.GetCameraState() == 0  && a == PlayerRef
				; In 1st person, MoveToNode does not place objects at the correct world coordinates of player nodes.
				; So we need to create a proxy object and move it to the node by other means.
				proxy = PlaceUrethraProxy(a, proxy)
			ElseIf proxy  ; returned to third person between two spurts
				proxy.Delete()
				proxy = None
			EndIf
			ObjectsSpurt(a, spurtPower, spurtAmount, dropS, dropM, dropL, proxy)
		Else
			Utility.Wait(0.06 * spurtAmount + 0.03 / (spurtPower + 0.2))  ; approximation for the time the spurt would have taken
		EndIf

		If StorageUtil.HasFormValue(a, "CS2_ejaculating")  ; still ejaculating?
			amountLeft -= spurtAmount
		Else  ; ejaculation has been forcibly stopped (by user hotkey, or framework mechanics)
			amountLeft = 0.0
		EndIf
		spurtNo += 1
		spurtWait = QRand(0.25, 1.0)
		Utility.Wait(spurtWait)
	EndWhile

	If proxy
		proxy.Delete()
	EndIf
EndFunction


; Launches one spurt from actor a, which can consist of several cum drops.
; Cum amount 1.0 roughly equates to 2 large drops (or 1 large, medium, and small), there's some randomization.
; More power makes the drops fly farther, disperses the spurt into smaller drops, and increases the spray cone.
Function ObjectsSpurt(Actor a, Float power, Float amount, Form dropS, Form dropM, Form dropL, ObjectReference proxy)
	Form dropType
	Float[] uRM = new Float[9]
	NetImmerse.GetNodeWorldRotationMatrix(a, "Urethra", uRM, False)  ; (uRM[1] uRM[4] uRM[7]) is the direction vector for the drops to be launched (local y axis of the node)
	Float vx
	Float vy
	Float vz
	Float speed
	Float spray = 0.2 * power / (amount * 4.0 + 0.8)
	Float size
	Float scale
	Float amountLeft = amount
	; launch multiple drops until there's no more cum left for this spurt
	While amountLeft >= 0.1
		; Everything inside this loop is highly time critical. Avoid using latent functions and external calls as much as possible.
		vx = uRM[1] + QRand(-spray, spray)
		vy = uRM[4] + QRand(-spray, spray)
		vz = uRM[7] + QRand(-spray, spray)
		speed =  amountLeft / amount * (power * 36.0 + 4.0)
		size = amountLeft / (power + 0.5 + 0.5 / power / power) + QRand(-0.15, 0.15)  ; smaller drops will occur at the end of the spurt, and both at very high and low power
		If size < 0.2
			dropType = dropS
			scale = size * 3.0 + 1.0
			amountLeft -= 0.1
		ElseIf size < 0.5
			dropType = dropM
			scale = size * 2.5 + 0.15
			amountLeft -= 0.3
		Else
			dropType = dropL
			scale = size * 2.0 - 0.45
			amountLeft -=  0.5
		EndIf
		(CS2CumPoolMarker.PlaceAtMe(dropType) as CS2DropScript).Launch(a, vx, vy, vz, speed, scale, proxy)
		Utility.Wait(0.03 / (power + 0.2))
	EndWhile
EndFunction


; Casts a series of spells from a marker object placed at the tip of the penis, each spell firing one spurt projectile.
; Allows to control the number of spurts, and (in a limited range) their direction.
Function EjaculateProjectiles(Actor a)
	Int numSpurts = (Math.Pow(GetCumAmount(a) + 0.2, 0.65) * 2.0 - 0.5) as Int  ; reduce the increase of spurts at high cum amounts
	If numSpurts < 1
		numSpurts = 1
	EndIf
	Int alphaVariant = (GetCumOpacity(a) * 10.0 + 0.5) as Int
	Spell spurtSpell
	ObjectReference caster = a.PlaceAtMe(CS2ProjectileLauncher)
	ObjectReference target = a.PlaceAtMe(CS2ProjectileLauncher)  ; to aim the spell in the correct direction
	Float[] uPos = new Float[3]
	Float[] uRM = new Float[9]
	Float targetX
	float targetY
	float targetZ
	Int i = 0
	While i < numSpurts
		Int spurtType = Utility.RandomInt(1, 4)
		If spurtType == 1
			spurtSpell = CS2ProjectileSpellsV1.GetAt(alphaVariant) as Spell
		ElseIf spurtType == 2
			spurtSpell = CS2ProjectileSpellsV2.GetAt(alphaVariant) as Spell
		ElseIf spurtType == 3
			spurtSpell = CS2ProjectileSpellsV3.GetAt(alphaVariant) as Spell
		ElseIf spurtType == 4
			spurtSpell = CS2ProjectileSpellsV4.GetAt(alphaVariant) as Spell
		EndIf
		If a.Is3DLoaded()
			NetImmerse.GetNodeWorldPosition(a, "Urethra", uPos, False)
			caster.SetPosition(uPos[0], uPos[1], uPos[2])
			NetImmerse.GetNodeWorldRotationMatrix(a, "Urethra", uRM, False)  ; (uRM[1] uRM[4] uRM[7]) is the direction vector for the spurts to be launched (local y axis of the node)
			targetX = uPos[0] + uRM[1] * 200.0 + QRand(-20.0, 20.0)
			targetY = uPos[1] + uRM[4] * 200.0 + QRand(-20.0, 20.0)
			targetZ = uPos[2] + uRM[7] * 200.0 + QRand(-10.0, 10.0) - ((i as Float) / (numSpurts as Float) - 0.5) * 180.0  ; later spurts fly lower, and (usually) less distance
			target.SetPosition(targetX, targetY, targetZ)
			spurtSpell.Cast(caster, akTarget = target)
		EndIf
		Utility.Wait(QRand(0.5, 1.0))

		If StorageUtil.HasFormValue(a, "CS2_ejaculating")  ; still ejaculating?
			i += 1
		Else  ; ejaculation has been forcibly stopped (by user hotkey, or framework mechanics)
			i = numSpurts
		EndIf
	EndWhile
	caster.Delete()
	target.Delete()
EndFunction


; Particles + projectiles hybrid (mode 2 with "hybridProjectiles": 1 in Cumshot/PPlusRules.json).
; The particle emitter draws the cum; for every particle spurt one invisible projectile
; (CS2HybridProjectileSpell) is fired at the same moment along the emitter axis, so the splash
; decal and splash sound of the projectile mode appear where the spurt lands.
Function EjaculateHybridProjectiles(Actor a, Float[] spurtTimes, Float startTime)
	ObjectReference caster = a.PlaceAtMe(CS2ProjectileLauncher)
	ObjectReference target = a.PlaceAtMe(CS2ProjectileLauncher)  ; to aim the spell in the correct direction
	Float[] uPos = new Float[3]
	Float[] uRM = new Float[9]
	Float delay
	Int i = 0
	While i < spurtTimes.Length
		delay = startTime + spurtTimes[i] - Utility.GetCurrentRealTime()
		If delay > 0.0
			Utility.Wait(delay)
		EndIf
		If !StorageUtil.HasFormValue(a, "CS2_ejaculating")  ; ejaculation has been forcibly stopped
			i = spurtTimes.Length
		Else
			If a.Is3DLoaded()
				NetImmerse.GetNodeWorldPosition(a, "Urethra", uPos, False)
				caster.SetPosition(uPos[0], uPos[1], uPos[2])
				NetImmerse.GetNodeWorldRotationMatrix(a, "Urethra", uRM, False)
				; The particle meshes' ParticleEmitter node points along the urethra's local Y axis
				; tilted 10 degrees up (towards local Z), with +-10 degrees of spread.
				target.SetPosition(uPos[0] + (uRM[1] * 0.985 + uRM[2] * 0.174) * 200.0 + QRand(-20.0, 20.0), \
					uPos[1] + (uRM[4] * 0.985 + uRM[5] * 0.174) * 200.0 + QRand(-20.0, 20.0), \
					uPos[2] + (uRM[7] * 0.985 + uRM[8] * 0.174) * 200.0 + QRand(-20.0, 20.0))
				hybridSpell.Cast(caster, akTarget = target)
			EndIf
			i += 1
		EndIf
	EndWhile
	caster.Delete()
	target.Delete()
EndFunction

; Start times (seconds after equip) of the spurts in Particles01..15 (index 0..14).
; Read from the emitter-active keys (NiBoolData) of the meshes; SOS and Static meshes share them.
; Generated by tools\gen_spurt_times.py - regenerate if the particle meshes change.
Float[] Function ParticleSpurtTimes(Int pIndex)
	Float[] t
	If pIndex == 0
		t = new Float[1]
		t[0] = 0.2
	ElseIf pIndex == 1
		t = new Float[2]
		t[0] = 0.2
		t[1] = 1.6
	ElseIf pIndex == 2
		t = new Float[3]
		t[0] = 0.2
		t[1] = 1.3
		t[2] = 2.7
	ElseIf pIndex == 3
		t = new Float[4]
		t[0] = 0.2
		t[1] = 1.1
		t[2] = 2.3
		t[3] = 3.7
	ElseIf pIndex == 4
		t = new Float[5]
		t[0] = 0.2
		t[1] = 0.9
		t[2] = 2.0
		t[3] = 3.2
		t[4] = 4.6
	ElseIf pIndex == 5
		t = new Float[5]
		t[0] = 0.2
		t[1] = 0.95
		t[2] = 2.5
		t[3] = 3.8
		t[4] = 5.4
	ElseIf pIndex == 6
		t = new Float[6]
		t[0] = 0.2
		t[1] = 0.95
		t[2] = 2.3
		t[3] = 3.7
		t[4] = 4.75
		t[5] = 6.3
	ElseIf pIndex == 7
		t = new Float[6]
		t[0] = 0.2
		t[1] = 1.2
		t[2] = 2.75
		t[3] = 4.3
		t[4] = 5.9
		t[5] = 7.4
	ElseIf pIndex == 8
		t = new Float[7]
		t[0] = 0.2
		t[1] = 1.2
		t[2] = 2.75
		t[3] = 4.3
		t[4] = 5.9
		t[5] = 7.0
		t[6] = 8.4
	ElseIf pIndex == 9
		t = new Float[8]
		t[0] = 0.2
		t[1] = 1.2
		t[2] = 2.75
		t[3] = 4.3
		t[4] = 5.9
		t[5] = 7.0
		t[6] = 8.3
		t[7] = 9.5
	ElseIf pIndex == 10
		t = new Float[9]
		t[0] = 0.2
		t[1] = 1.2
		t[2] = 2.75
		t[3] = 4.3
		t[4] = 5.9
		t[5] = 7.0
		t[6] = 8.3
		t[7] = 9.5
		t[8] = 10.6
	ElseIf pIndex == 11
		t = new Float[10]
		t[0] = 0.2
		t[1] = 1.2
		t[2] = 2.75
		t[3] = 4.3
		t[4] = 5.9
		t[5] = 7.0
		t[6] = 8.3
		t[7] = 9.4
		t[8] = 10.4
		t[9] = 11.6
	ElseIf pIndex == 12
		t = new Float[11]
		t[0] = 0.2
		t[1] = 1.2
		t[2] = 2.75
		t[3] = 4.3
		t[4] = 5.9
		t[5] = 7.0
		t[6] = 8.3
		t[7] = 9.4
		t[8] = 10.4
		t[9] = 11.4
		t[10] = 12.6
	ElseIf pIndex == 13
		t = new Float[12]
		t[0] = 0.2
		t[1] = 1.2
		t[2] = 2.75
		t[3] = 4.3
		t[4] = 5.9
		t[5] = 7.0
		t[6] = 8.3
		t[7] = 9.4
		t[8] = 10.4
		t[9] = 11.4
		t[10] = 12.5
		t[11] = 13.65
	ElseIf pIndex == 14
		t = new Float[13]
		t[0] = 0.2
		t[1] = 1.2
		t[2] = 2.75
		t[3] = 4.3
		t[4] = 5.9
		t[5] = 7.0
		t[6] = 8.3
		t[7] = 9.4
		t[8] = 10.4
		t[9] = 11.35
		t[10] = 12.5
		t[11] = 13.55
		t[12] = 14.75
	EndIf
	Return t
EndFunction


; Launches a series of invisible tracer objects that can be detected by a trigger volume.
; Used (optionally) during mesh or particle ejaculations, which can not be detected otherwise.
Function EmitTracers(Actor a, Float totalTime, Float timePerObject, Float preTime)
	ObjectReference proxy = None
	Float[] uRM = new Float[9]
	Float speed
	Int numObjects = (totalTime / timePerObject) as Int
	Utility.Wait(preTime)
	totalTime -= preTime
	While numObjects > 0
		If a.Is3DLoaded()
			NetImmerse.GetNodeWorldRotationMatrix(a, "Urethra", uRM, False)  ; (uRM[1] uRM[4] uRM[7]) is the direction vector for the drops to be launched (local y axis of the node)
			If Game.GetCameraState() == 0  && a == PlayerRef
				; In 1st person, MoveToNode does not place objects at the correct world coordinates of player nodes.
				; So we need to create a proxy object and move it to the node by other means.
				proxy = PlaceUrethraProxy(a, proxy)
			ElseIf proxy  ; returned to third person since last object had been launched
				proxy.Delete()
				proxy = None
			EndIf
			If Config.ejaculationMode == 1  ; try to roughly match the mesh animation
				speed = 20.0 + numObjects * 10.0
			Else
				speed = 30.0
			EndIf
			(CS2CumPoolMarker.PlaceAtMe(CS2Tracer) as CS2DropScript).Launch(a, uRM[1], uRM[4], uRM[7], speed, 1.0, proxy)
		EndIf

		If totalTime > timePerObject
			Utility.Wait(timePerObject)
			totalTime -= timePerObject
		Else
			Utility.Wait(totalTime)
			totalTime == 0.0
		EndIf
		
		If StorageUtil.HasFormValue(a, "CS2_ejaculating")  ; still ejaculating?
			numObjects -= 1
		Else  ; ejaculation has been forcibly stopped (by user hotkey, or framework mechanics)
			numObjects = 0
		EndIf
	EndWhile

	If proxy
		proxy.Delete()
	EndIf
EndFunction


; Create a proxy object (an invisible activator) at the urethra node to launch drop objects from.
; Or just move it to the node if it already exists.
; To be used in 1st person mode where the MoveToNode function doesn't work correctly.
ObjectReference Function PlaceUrethraProxy(Actor a, ObjectReference proxy)
	If proxy == None
		proxy = a.PlaceAtMe(CS2ProjectileLauncher)
	EndIf
	
	Float[] uPos = new Float[3]
	NetImmerse.GetNodeWorldPosition(a, "Urethra", uPos, False)
	proxy.SetPosition(uPos[0], uPos[1], uPos[2])

	While !proxy.Is3DLoaded()
		Utility.Wait(0.01)
	EndWhile
;/	Float[] uRot = new Float[3]
	NetImmerse.GetNodeWorldRotationEuler(a, "Urethra", uRot, False)
	proxy.SetAngle(uRot[0], uRot[1], uRot[2])  /;
	; GetNodeWorldRotationEuler is bugged, it just fills the array with the local rotation angles, exact same output as GetNodeLocalRotationEuler.
	; In comparison, GetNodeWorldRotationMatrix always works correctly.
	; It's possible to convert the matrix to Euler angles in Papyrus, but that requires a lot of external calls to the Math library, and execution time.
	; So for now we just match the actor's Z rotation and live with the inaccuracy / weird look in some situations.
	proxy.SetAngle(0.0, 0.0, a.GetAngleZ())

	Return proxy
EndFunction


; Unequip the cumshot armor object if the actor is in a sex scene,
; otherwise remove all possible cumshot objects that might have stacked up in the actor's inventory.
; The ejaculation animation can be switched off with "animation": 0 in
; Cumshot/PPlusRules.json (JsonUtil loads the file on first access).
Bool Function AnimationEnabled()
	Return JsonUtil.GetPathIntValue("Cumshot/PPlusRules", ".animation", 1) != 0
EndFunction


; Hybrid particles + projectiles, switched with "hybridProjectiles" in Cumshot/PPlusRules.json
; (default on). Needs "Cumshot - Particles Hybrid.esp" for the invisible projectile spell.
Bool Function HybridEnabled()
	Return hybridSpell != None && JsonUtil.GetPathIntValue("Cumshot/PPlusRules", ".hybridProjectiles", 1) != 0
EndFunction


Function RemoveCumshot(Actor a, Float waitTime = 0.0, Bool forceRemove = False)
	If waitTime > 0.0
		Utility.Wait(waitTime)
	EndIf
	If !StorageUtil.HasFormValue(a, "CS2_ejaculating") && !forceRemove  ; check if it had already been removed in the meantime
		Return
	EndIf

	Bool isInSexScene = False
	If SexLabInstalled
		isInSexScene = a.GetFactionRank(SexLab_AnimatingFaction) >= 0 || a.HasKeywordString("SexLabActive")
	EndIf
	If FlowerGirlsInstalled
		isInSexScene = isInSexScene || StorageUtil.HasIntValue(a, "CS2_inFGScene")
	EndIf

	; Put the penis back after the pulse animation: still in the scene -> erect and straight
	; again (SexLab P+ only ever uses SOSBend0), otherwise -> flaccid.
	If StorageUtil.GetIntValue(a, "CS2_AnimPlayed", 0) == 1
		If isInSexScene && !forceRemove
			Debug.SendAnimationEvent(a, "SOSFastErect")
			Utility.Wait(0.2)
			Debug.SendAnimationEvent(a, "SOSBend0")
		Else
			Debug.SendAnimationEvent(a, "SOSFlaccid")
			StorageUtil.UnsetIntValue(a, "CS2_AnimPlayed")
		EndIf
	EndIf

	String actionTaken
	If isInSexScene && !forceRemove && a != PlayerRef
		Form cumObject = StorageUtil.PluckFormValue(a, "CS2_ejaculating")
		If cumObject
			; don't fully remove, it will cause NPCs to redress on further ejaculations during a scene
			a.UnequipItem(cumObject, abPreventEquip = True, abSilent = True)
			actionTaken = "unequipped"
		EndIf
	Else
		StorageUtil.UnsetFormValue(a, "CS2_ejaculating")
		a.RemoveItem(CS2UrethraAddons, 9999, True)  ; a big heap of each item in this form list
		actionTaken = "removed"
	EndIf

	If debugMsgLevel > 0
		If waitTime > 0.0
			DebugMessage(a.GetLeveledActorBase().GetName() + ": Cumshot " + actionTaken + " after " + waitTime + " seconds.", False)
		Else
			DebugMessage(a.GetLeveledActorBase().GetName() + ": Cumshot " + actionTaken + ".", False)
		EndIf
	EndIf

	If a == PlayerRef && Game.GetCameraState() == 3  ; TFC
		a.QueueNiNodeUpdate()  ; fixes player geometry not updating in TFC mode

	EndIf
EndFunction


; --------------------------------------------------------------------
;                          Utility functions
; --------------------------------------------------------------------

; Getting various ejaculation related stats for an actor (or global values if the individual ones are not defined)
;
Float Function GetCumAmount(Actor a)
	Float value = StorageUtil.GetFloatValue(a, "CS2CumAmount", -1.0)
	If value == -1.0  ; not defined on the actor
		value = Config.cumAmount
	EndIf
	If Config.draining
		Float lastOrgasmTime = StorageUtil.GetFloatValue(a, "CS2_LastOrgasmTime", -1.0)
		If lastOrgasmTime == -1.0  ; no time had been stored before
			value *= QRand(0.8, 1.5)
		Else
			value *= 2.5 - 1.5 / (Math.Pow((Utility.GetCurrentGameTime() - lastOrgasmTime) / 5.0, 0.4) + 0.6)
			; With this formula, cum amount recovers to about 30% after 15 minutes, to 100% after 12 hours,
			; to 1.5 the normal amount after 4 days wait. The factor approaches 2.5 at infinite waiting time.
		EndIf
	EndIf
	If Config.useArousal
		Float arousal = GetArousal(a) as Float
		If arousal >= 0.0  ; valid result
			value *= 0.75 + arousal * 0.0075
		EndIf
	EndIf
	Return value
EndFunction
;
Float Function GetEjaculationPower(Actor a)
	Float value = StorageUtil.GetFloatValue(a, "CS2EjaculationPower", -1.0)
	If value == -1.0  ; not defined on the actor
		value = Config.ejaculationPower
	EndIf
	If Config.useArousal
		Float arousal = GetArousal(a) as Float
		If arousal >= 0.0  ; valid result
			value *= 0.75 + arousal * 0.01
		EndIf
	EndIf
	Return value
EndFunction
;
Float Function GetSpurtRatio(Actor a)
	Float value = StorageUtil.GetFloatValue(a, "CS2SpurtRatio", -1.0)
	If value == -1.0  ; not defined on the actor
		value = Config.spurtRatio
	EndIf
	Return value
EndFunction
;
Float Function GetCumOpacity(Actor a)
	Float value = StorageUtil.GetFloatValue(a, "CS2CumOpacity", -1.0)
	If value == -1.0  ; not defined on the actor
		value = Config.cumAlpha
	EndIf
	Return value
EndFunction


; Asynchronously update the value of the actor's sla_Arousal faction so it can't stall the Ejaculate() function
Event UpdateArousal(Form a)
	If ArousedModType == 1  ; SexLab Aroused Redux
		
	ElseIf ArousedModType == 2  ; Aroused Redux for Flower Girls

	EndIf
EndEvent
; Get actor arousal from either SexLab Aroused, or Aroused Redux for Flower Girls
Int Function GetArousal(Actor a)
	If ArousedInstalled
		Return a.GetFactionRank(Aroused_Faction)
	Else
		Return -2  ; error / invalid
	EndIf
EndFunction

; Make Aroused update an actor's stats as if they had an orgasm
Function ArousedSimulateOrgasm(Actor a, Int exposure)
	If ArousedModType == 1  ; SexLab Aroused Redux
	
	ElseIf ArousedModType == 2  ; Aroused Redux for Flower Girls
	
	EndIf
EndFunction


; check if actor values are still in extended range when no longer allowed to, and clamp them if necessary
Function ClampActorValues(Actor a)
	If !Config.allowUnrealistic
		Float value
		value = StorageUtil.GetFloatValue(a, "CS2CumAmount", -1.0)
		If value > 15.0
			StorageUtil.SetFloatValue(a, "CS2CumAmount", 15.0)
		EndIf
		value = StorageUtil.GetFloatValue(a, "CS2EjaculationPower", -1.0)
		If value > 2.0
			StorageUtil.SetFloatValue(a, "CS2EjaculationPower", 2.0)
		EndIf
		value = StorageUtil.GetFloatValue(a, "CS2SpurtRatio", -1.0)
		If value > 10.0
			StorageUtil.SetFloatValue(a, "CS2SpurtRatio", 10.0)
		EndIf
	EndIf
EndFunction


; Tries to find out if an actor has an SOS or equipable schlong and can ejaculate (> 0, or -1) or not (0)
Int Function HasSchlongItem(Actor a)
	Int i = 0
	While i < installedSchlongs
		If a.IsInFaction(schlongFaction[i])
			Return -1  ; actor is schlonged through SOS
		EndIf
		i += 1
	EndWhile

	If a.IsEquipped(CS2EquipableSchlongs)  ; any of the known schlongs in the FormList
		i = 0
		While i < knownEqSchlongs
			If eqSchlongs[i]  ; don't check None entries (from forms whose mods are not installed)
				If a.IsEquipped(eqSchlongs[i])
					return i + 1  ; actor has an equipable schlong, use value as index for adjustment key
				EndIf
			EndIf
			i += 1
		EndWhile
	EndIf

	Return 0
EndFunction


; Checks if the ActorBase (or the actor's race) is known to have a special body with included penis
; Return value > 0 is used as index for adjustment key
Int Function HasSpecialBody(Actor a, Bool isFemale)
	; scan the whole list for ActorBase entries first because they take priority over Race entries
	ActorBase aBase = a.GetLeveledActorBase()
	Int i = 0
	While i < knownSpecialBodies
		If specialBodies[i]  ; don't check None entries (from forms whose mods are not installed)
			If (specialBodies[i] as ActorBase) == aBase  ; the entry is an ActorBase and matches the actor's base record
				Return i + 1
			EndIf
		EndIf
		i += 1
	EndWhile
	; then the Race entries
	Race aRace = a.GetRace()
	i = 0
	While i < knownSpecialBodies
		If specialBodies[i]
			If (specialBodies[i] as Race) == aRace
				If specialRaceFemale[i] == isFemale  ; the entry is a race and matches the actor's race and gender
					Return i + 1
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return 0
EndFunction


; Find out what type of genitals are active for the selected actor (needed for the MCM Genital data tab)
; This and the following functions exist on the game script because they need to work with data that is maintained here.
Function IdentifyGenitals(Actor a)
	ActorBase aBase = a.GetLeveledActorBase()
	Bool isFemale = (aBase.GetSex() == 1)
	Race aRace = a.GetRace()

	If Config.maleBodyClass == 1  ; SOS Full is installed
		; check if the actor has an SOS addon known to Cumshot
		Int i = 0
		While i < installedSchlongs
			If a.IsInFaction(schlongFaction[i])
				If schlongRace[i] == aRace.GetName() || schlongRace[i] == "DFLT"
					Config.GenitalData(1, schlongFaction[i], True, schlongKey[i], schlongRace[i] != "DFLT")
					Return
				EndIf
			EndIf
			i += 1
		EndWhile

		; check if the actor has an unknown SOS addon
		Form aSOSAddon = SOS_API.Get().GetSchlong(a)
		If aSOSAddon
			Config.GenitalData(1, (aSOSAddon as SOS_AddonQuest_Script).SOS_Addon_Faction)
			Return
		EndIf
	EndIf

	; check if the actor has a known equipable schlong
	If a.IsEquipped(CS2EquipableSchlongs)  ; any of the known schlongs in the FormList
		Int i = 0
		While i < knownEqSchlongs
			If eqSchlongs[i]  ; don't check None entries (from forms whose mods are not installed)
				If a.IsEquipped(eqSchlongs[i])
					Config.GenitalData(2, eqSchlongs[i], True, eqSchlongKeys[i])
					Return
				EndIf
			EndIf
			i += 1
		EndWhile
	EndIf

	; check if the actor has an unknown slot 52 item equipped
	Armor slot52item = a.GetWornForm(0x00400000) as Armor
	If slot52item == None
		slot52item = a.GetWornForm(0x40000000) as Armor
	EndIf
	If slot52item
		If !(slot52item.HasKeywordString("ArmorClothing") || slot52item.HasKeywordString("ArmorLight") || slot52item.HasKeywordString("ArmorHeavy") \
			|| slot52item.HasKeywordString("VendorItemClothing") || slot52item.HasKeywordString("VendorItemArmor"))
			Config.GenitalData(2, slot52item)
			Return
		EndIf
	EndIf

	; check if the actor's ActorBase or race is known to have a special body with included penis
	; scan the whole list for ActorBase entries first because they take priority over Race entries
	Int i = 0
	While i < knownSpecialBodies
		If specialBodies[i]  ; don't check None entries (from forms whose mods are not installed)
			If (specialBodies[i] as ActorBase) == aBase  ; the entry is an ActorBase and matches the actor's base record
				Config.GenitalData(0, specialBodies[i], True, specialBodyKeys[i])
				Return
			EndIf
		EndIf
		i += 1
	EndWhile
	; then the Race entries
	i = 0
	While i < knownSpecialBodies
		If specialBodies[i]
			If (specialBodies[i] as Race) == aRace
				If specialRaceFemale[i] == isFemale  ; the entry is a race and matches the actor's race and gender
					Config.GenitalData(0, specialBodies[i], True, specialBodyKeys[i], True, isFemale)
					Return
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	; actor seems to only be wearing the default body
	Config.GenitalData(0)
EndFunction


Function AddDatabaseEntry(Int type, Form genForm, String genKey, Form validFor = None, Bool forFemale = False)
	String fullKey = genKey
	If type == 0  ; special body
		If (validFor as Race) && forFemale
			fullKey = genKey + "@f"
		EndIf
		JsonUtil.SetPathFormValue(jfile, ".SpecialBodies." + fullKey, genForm)
		BuildSpecialBodiesList()
	ElseIf type == 1  ; SOS addon
		If (validFor as Race)
			fullKey = genKey + "@" + (validFor as Race).GetName()
		EndIf
		JsonUtil.SetPathFormValue(jfile, ".SOSAddons." + fullKey, genForm)
		BuildSchlongList()
	ElseIf type == 2  ; equipable slot 52 item
		JsonUtil.SetPathFormValue(jfile, ".EquipObjects." + fullKey, genForm)
		BuildEquipableSchlongList()
	EndIf

	Float[] transforms
	If type == 1 && (validFor as Race)  ; racial variant of an SOS addon - copy the values from the general entry
		transforms = JsonUtil.FloatListToArray(jfile, genKey)
	Else  ; otherwise use the SOS Default transforms
		transforms = JsonUtil.FloatListToArray(jfile, Config.GetDefaultKey())
	EndIf
	JsonUtil.FloatListCopy(jfile, fullKey, transforms)

	JsonUtil.Save(jfile, minify = True)
EndFunction


Function RemoveDatabaseEntry(Int type, String fullKey, Form validFor = None, Bool forFemale = False)
	String baseKey = fullKey
	Int atPos = StringUtil.Find(fullKey, "@")
	If atPos >= 0  ; there's a "@" inside the full key
		baseKey = StringUtil.Substring(fullKey, 0, atPos)
	EndIf
	If type == 0  ; special body
		JsonUtil.ClearPath(jfile, ".SpecialBodies." + fullKey)
		JsonUtil.FloatListClear(jfile, fullKey)
		BuildSpecialBodiesList()
	ElseIf type == 1  ; SOS addon
		If (validFor as Race)
			; unchecking "is racial variant" makes the entry the general one, so move the variant transform data to the general entry
			Float[] transforms = JsonUtil.FloatListToArray(jfile, fullKey)
			JsonUtil.FloatListCopy(jfile, baseKey, transforms)
			JsonUtil.ClearPath(jfile, ".SOSAddons." + fullKey)
			JsonUtil.FloatListClear(jfile, fullKey)
		Else  ; removing a general entry also removes all racial variants for this schlong addon form
			Form addonForm = JsonUtil.GetPathFormValue(jfile, ".SOSAddons." + fullKey)
			Int idx = schlongFaction.Find(addonForm as Faction)
			While idx >= 0  ; Find() returns -1 when the faction is not found
				JsonUtil.ClearPath(jfile, ".SOSAddons." + schlongKey[idx])
				JsonUtil.FloatListClear(jfile, schlongKey[idx])
				idx = schlongFaction.Find(addonForm as Faction, idx + 1)
			EndWhile
		EndIf
		BuildSchlongList()
	ElseIf type == 2  ; equipable slot 52 item
		JsonUtil.ClearPath(jfile, ".EquipObjects." + fullKey)
		JsonUtil.FloatListClear(jfile, fullKey)
		BuildEquipableSchlongList()
	EndIf

	JsonUtil.Save(jfile, minify = True)
EndFunction


Int Function RenameDatabaseEntry(Int type, Form genForm, String oldKey, String newKey)
	If StringUtil.Find(newKey, "@") >= 0
		Return -2  ; Error - name must not contain an '@'
	EndIf
	String oldBaseKey = oldKey
	Int atPos = StringUtil.Find(oldKey, "@")
	If atPos >= 0  ; there's a "@" inside the full key
		oldBaseKey = StringUtil.Substring(oldKey, 0, atPos)
	EndIf
	String[] knownKeys = JsonUtil.PathMembers(jfile, ".floatList")
	If knownKeys.Find(newKey) >= 0 || knownKeys.Find(newKey + "@f") >= 0
		Return -1  ; Error - key already exists
	EndIf

	String path
	If type == 0
		path = ".SpecialBodies"
	ElseIf type == 1
		path = ".SOSAddons"
	Else  ; type == 2
		path = ".EquipObjects"
	EndIf

	; now go through all existing entries in the category / type
	knownKeys = JsonUtil.PathMembers(jfile, Path)
	String scope
	Float[] transforms
	Int i = 0
	While i < knownKeys.Length
		; If the entry's form matches the form of the to-be-renamed entry, rename this one as well
		If JsonUtil.GetPathFormValue(jfile, path + "." + knownKeys[i]) == genForm
			; isolate a possible race/gender descriptor, it needs to be appended to the renamed key
			atPos = StringUtil.Find(knownKeys[i], "@")
			If atPos >= 0
				scope = StringUtil.Substring(knownKeys[i], atPos)
			Else
				scope = ""
			EndIf
			; JsonUtil can't rename keys, so create new ones and delete the old.
			JsonUtil.SetPathFormValue(jfile, path + "." + newKey + scope, genForm)
			JsonUtil.ClearPath(jfile, path + "." + knownKeys[i])
			transforms = JsonUtil.FloatListToArray(jfile, knownKeys[i])
			JsonUtil.FloatListCopy(jfile, newKey + scope, transforms)
			JsonUtil.FloatListClear(jfile, knownKeys[i])
		EndIf
		i += 1
	EndWhile

	If type == 0
		BuildSpecialBodiesList()
	ElseIf type == 1
		BuildSchlongList()
	Else  ; type == 2
		BuildEquipableSchlongList()
	EndIf

	JsonUtil.Save(jfile, minify = True)
	Return 0  ; success
EndFunction


; Change an entry for bodies with integrated penis between ActorBase and Race
Function SwitchDatabaseBodyEntry(String genKey, Form validFor, Bool forFemale = False, Bool keepRaceEntry = False)
	String newKey
	Float[] transforms = JsonUtil.FloatListToArray(jfile, genKey)

	; Changing to race: scan for already existing entries for that race form
	If (validFor as Race)
		String[] knownKeys = JsonUtil.PathMembers(jfile, ".SpecialBodies")
		Int raceEntrySameGender = -1
		Int raceEntryOppositeGender = -1
		Int i = 0
		While i < knownKeys.Length
			If JsonUtil.GetPathFormValue(jfile, ".SpecialBodies." + knownKeys[i]) == validFor
				If forFemale == (StringUtil.Find(knownKeys[i], "@f") >= 0)
					raceEntrySameGender = i
				Else
					raceEntryOppositeGender = i
				EndIf
			EndIf
			i += 1
		EndWhile

		If raceEntrySameGender == -1 && raceEntryOppositeGender == -1  ; no Race entry for the actor's race exists
			newKey = CreateUniqueKey((validFor as Race).GetName())
			If forFemale
				newKey += "@f"
			EndIf
			JsonUtil.SetPathFormValue(jfile, ".SpecialBodies." + newKey, validFor)
			JsonUtil.FloatListCopy(jfile, newKey, transforms)
		Else  ; a race entry (same and/or other gender) already exists
			If raceEntrySameGender >= 0
				; just copy transforms to existing entry
				JsonUtil.FloatListCopy(jfile, knownKeys[raceEntrySameGender], transforms)
			EndIf
			If raceEntryOppositeGender >= 0
				; take new entry's name from other gender's entry, and add / remove the "@f" accordingly
				newKey = knownKeys[raceEntryOppositeGender]
				If forFemale
					newKey += "@f"
				Else
					newKey = StringUtil.Substring(newKey, 0, StringUtil.GetLength(newKey) - 2)
				EndIf
				JsonUtil.SetPathFormValue(jfile, ".SpecialBodies." + newKey, validFor)
				JsonUtil.FloatListCopy(jfile, newKey, transforms)
			EndIf
		EndIf

		; and delete the ActorBase entry in any of these cases
		JsonUtil.ClearPath(jfile, ".SpecialBodies." + genKey)
		JsonUtil.FloatListClear(jfile, genKey)

	ElseIf (validFor as ActorBase)  ; changing Race to ActorBase entry
		newKey = CreateUniqueKey((validFor as ActorBase).GetName())
		JsonUtil.SetPathFormValue(jfile, ".SpecialBodies." + newKey, validFor)
		JsonUtil.FloatListCopy(jfile, newKey, transforms)
		If !keepRaceEntry
			JsonUtil.ClearPath(jfile, ".SpecialBodies." + genKey)
			JsonUtil.FloatListClear(jfile, genKey)
		EndIf
	EndIf

	BuildSpecialBodiesList()
	JsonUtil.Save(jfile, minify = True)
EndFunction


; checks if the tentative key <keyBase> is already in use, and appends a number if needed
String Function CreateUniqueKey(String keyBase)
	If keyBase == ""
		keyBase = "New entry"
	EndIf
	String[] knownKeys = JsonUtil.PathMembers(jfile, ".floatList")
	If knownKeys.Find(keyBase) >= 0 || knownKeys.Find(keyBase + "@f") >= 0  ; don't need to search for "@race" keys because base entry is always present
		Int numero = 2
		While knownKeys.Find(keyBase + " #" + numero) >= 0 || knownKeys.Find(keyBase + " #" + numero + "@f") >= 0
			numero += 1
		EndWhile
		keyBase += " #" + numero
	EndIf
	Return keyBase
EndFunction


; A Wichmann-Hill random number generator
; used to avoid suspending script execution by making external calls to Utility.RandomFloat()
Float Function QRand(Float min = 0.0, Float max = 1.0)
	rnd_s1 = (171 * rnd_s1) % 30269
	rnd_s2 = (172 * rnd_s2) % 30307
	rnd_s3 = (170 * rnd_s3) % 30323
	Float r = rnd_s1 / 30269.0 + rnd_s2 / 30367.0 + rnd_s3 / 30323.0
	r -= (r as Int)
	Return  r * (max - min) + min
EndFunction


; Set initial seed values for the RNG. Can also be called from MCM if generation gets stuck on always the same values.
Function ResetQRand()
	Int realTimeMod = (Utility.GetCurrentRealTime() as Int) % 1000
	rnd_s1 = 13254 + realTimeMod
	rnd_s2 = 4931 + realTimeMod
	rnd_s3 = 24178 + realTimeMod
EndFunction


Function DebugMessage(String msg, Bool showIngame = True)
	If debugMsgLevel >= 1
		String msgPlus = msg
		If StringUtil.Substring(msg, 0, 3) != "CS2"
			msgPlus = "CS2: " + msg
		EndIf
		Debug.Trace(msgPlus)
		If debugMsgLevel >= 2
			If SexLabInstalled
				MiscUtil.PrintConsole(msgPlus)
			EndIf
			If debugMsgLevel == 3 && showIngame
				Debug.Notification(msg)
			EndIf
		EndIf
	EndIf
EndFunction
