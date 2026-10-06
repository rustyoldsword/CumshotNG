ScriptName CS2ConfigScript Extends SKI_ConfigBase Conditional

CS2GameScript Property Main Auto
Actor Property playerRef Auto

Int Property maleBodyClass Auto Hidden
Int Property maleBody Auto Hidden
String Property maleBodyName Auto Hidden

; Settings - General
Bool Property alwaysShowEjac Auto
Int Property triggerKey Auto
Int Property reloadJsonKey Auto
Float Property equipDelay Auto
Int Property debugMsgLevel Auto
Int Property orgasmDetectMode Auto Hidden
Bool Property victimsEjaculate Auto
Bool Property useStageEvent Auto Conditional
Bool Property useArousal Auto
Int Property hotkeyExposure Auto

; Settings - Visuals
Int Property ejaculationMode Auto
Bool Property showDrip Auto
Bool Property tracerObject Auto
Float Property cumAmount Auto
Float Property ejaculationPower Auto
Float Property spurtRatio Auto
Float Property cumAlpha Auto
Bool Property allowUnrealistic Auto
Bool Property draining Auto

; Settings - Genitals
Bool genShowingNPC
Actor genActor
ActorBase genActorBase
Bool genIsFemale
Race genRace
Int Property genType Auto Hidden  ; 0 - integrated with body, 1 - SOS addon, 2 - equipable item
Form Property genForm Auto Hidden
Bool Property genActive Auto Hidden
String Property genKey Auto Hidden
Bool Property genIsRacial Auto Hidden
Bool Property genForFemale Auto Hidden
Bool Property genMalesAlways Auto Hidden
Bool genWeightDependent
Bool genKeepWDVOnReset
Float[] genMove0
Float[] genMove100
Float[] genRotate

; installation and compatibility
GlobalVariable Property CS2SexLabSupported Auto       ; These two are defined as 0 in Cumshot.esp,
GlobalVariable Property CS2FlowerGirlsSupported Auto  ; and overridden to 1 by their respective addon module.
Bool SexLabInstalled       ;
Bool FlowerGirlsInstalled  ; These variables mirror properties of CS2GameScript, for faster access
Bool ArousedInstalled      ;
Bool critical
Bool niOverrideReqMet

Int numBodies
String[] bodyNames
String[] ejacModeNames
String[] debugLvNames
String[] detectModeNames
String[] slActionsNames
String[] genAppliesToNames
String jfile = "Cumshot/AdjustValues"

; SexLab animation rules
MiscObject Property CS2EjaculationRulesSL Auto
String[] Property animRegSL Auto Hidden
String[] Property animNameSL Auto Hidden
Int[] Property animPosCountSL Auto Hidden
Int[] Property animValSL Auto Hidden
Int Property numRegAnimsSL Auto Hidden
Int Property animsPerPage = 120 AutoReadOnly Hidden
Int numAnimPages
Int curAnimPage
Bool Property defaultRulesSet = False Auto Hidden  ; defaults will be reapplied when updating
Bool Property forceClearRules = False Auto Hidden  ; only when manually reapplying defaults
Bool Property rebuilding Auto Hidden

; internal IDs for MCM options
Int alwaysOID
Int triggerKeyOID
Int delayOID
Int debugLvOID
Int reloadJsonKeyOID
Int resetRngOID
Int orgasmDetectOID
Int victimsOID
Int stageEventOID
Int arousalOID
Int exposureOID
Int ejacModeOID
Int dripOID
Int tracerOID
Int amountOID
Int powerOID
Int ratioOID
Int alphaOID
Int indAmountOID
Int indPowerOID
Int indRatioOID
Int indAlphaOID
Int unrealisticOID
Int drainingOID
Int bodyOID
Int[] animOID
Int explainOID  ; no longer in use
Int rebuildOID  ; no longer in use
Int animPageOID
Int animPageDummyOID
Int slActionsOID
Int genActorOID
Int genActiveOID
Int genKeyOID
Int genIsRacialOID
Int genappliesToOID
Int genMalesAlwaysOID
Int genWeightDependentOID
Int genMove0xOID
Int genMove0yOID
Int genMove0zOID
Int genMove100xOID
Int genMove100yOID
Int genMove100zOID
Int genRotateOID

Actor crosshairRef
ActorBase crosshairBase
String crosshairName

Int installedVersion
String versionString
Int Function GetVersion()
	versionString = "2.3"
	Return 230
EndFunction


; --------------------------------------------------------------------
;                           Initialization
; --------------------------------------------------------------------

; early MCM initialization stuff that never changes
Event OnConfigInit()
	ejacModeNames = new String[4]
	ejacModeNames[0] = "Animated mesh"
	ejacModeNames[1] = "Particles"
	ejacModeNames[2] = "Drop objects"
	ejacModeNames[3] = "Projectiles"
	debugLvNames = new String[4]
	debugLvNames[0] = "No messages"
	debugLvNames[1] = "Log"
	debugLvNames[2] = "Log+Console"
	debugLvNames[3] = "Log+Con+Ingame"
	detectModeNames = new String[3]
	detectModeNames[0] = "Individually"
	detectModeNames[1] = "Hybrid mode"
	detectModeNames[2] = "Final stage"
	;/slActionsNames = new String[5]
	slActionsNames[0] = "(cancel)"
	slActionsNames[1] = "Explanation"
	slActionsNames[2] = "Rebuild animation list"
	slActionsNames[3] = "Rebuild animation list, reload rules"
	slActionsNames[4] = "Save custom rules to file"/;
	genAppliesToNames = new String[2]
	genAppliesToNames[0] = "This character only"
	genAppliesToNames[1] = "This character's race"
EndEvent


; former event OnGameReload(); it's now called from Main.Initialize() because it relies on data provided there.
Function Initialize()
	Parent.OnGameReload()

	; copy to local variables for faster access
	SexLabInstalled = Main.SexLabInstalled
	FlowerGirlsInstalled = Main.FlowerGirlsInstalled
	ArousedInstalled = Main.ArousedInstalled

	; setting up MCM pages depending on mod health and installed frameworks
	If DependenciesError()
		Pages = new String[1]
		Pages[0] = "ERROR"
	ElseIf SexLabInstalled
		Pages = new String[4]
		Pages[0] = "General"
		Pages[1] = "Visuals"
		Pages[2] = "Genital data"
		;Pages[3] = "Animations (SexLab)"
	Else
		Pages = new String[3]
		Pages[0] = "General"
		Pages[1] = "Visuals"
		Pages[2] = "Genital data"
	EndIf

	CheckForBodyMods()

	If installedVersion < GetVersion()
		Main.DebugMessage("CS2: Updating from version " + installedVersion + " to " + GetVersion(), False)
		defaultRulesSet = False

		If GetVersion() >= 201 && installedVersion <= 200
			If equipDelay < 0.3
				equipDelay = 0.3
			EndIf
		EndIf
		;/If GetVersion() >= 220 && installedVersion < 220
			slActionsNames = new String[5]
			slActionsNames[0] = "(cancel)"
			slActionsNames[1] = "Explanation"
			slActionsNames[2] = "Rebuild animation list"
			slActionsNames[3] = "Rebuild animation list, reload rules"
			slActionsNames[4] = "Save custom rules to file"
		EndIf/;
		If GetVersion() >= 230 && installedVersion < 230
			genAppliesToNames = new String[2]
			genAppliesToNames[0] = "This character only"
			genAppliesToNames[1] = "This character's race"
			genMalesAlways = True
			Main.debugMsgLevel = debugMsgLevel
		EndIf
		;
		; add update maintenance code for future versions here
		;
		installedVersion = GetVersion()
	EndIf

	curAnimPage = 1
EndFunction


Bool Function DependenciesError()
	critical = False

	If SKSE.GetVersion() < 1
		Debug.MessageBox("-=Cumshot =-\nSKSE is not correctly installed or not loaded. Cumshot won't work without it. Please install the correct version for your game.")
		critical = True
	Else
		Int papyrusUtilVer = PapyrusUtil.GetVersion()
		Int papyrusUtilScriptVer = PapyrusUtil.GetScriptVersion()
		Main.DebugMessage("PapyrusUtil is version " + papyrusUtilVer + " (script version = " + papyrusUtilScriptVer + ")", False)
		If papyrusUtilVer == 0
			Debug.MessageBox("-= Cumshot =-\nPapyrusUtil is not installed. Cumshot won't work without it. Please install the latest version. SexLab has PapyrusUtil included.")
			critical = True
		ElseIf papyrusUtilVer < 33 || papyrusUtilScriptVer < 33
			Debug.MessageBox("-= Cumshot =-\nThe installed version of PapyrusUtil is outdated. Version 3.3 or higher is needed. Things may not work properly.\nMaybe PapyrusUtil's files are overwritten by another mod.")
		EndIf

		Int niOverrideVer = NiOverride.GetScriptVersion()
		Main.DebugMessage("NiOverride is version " + niOverrideVer, False)
		If niOverrideVer >= 6
			niOverrideReqMet = True
		Else
			niOverrideReqMet = False
			Debug.MessageBox("-= Cumshot =-\nNetImmerse Override is not installed or out of date. Cumshot will not work properly.\nPlease install the latest version, or RaceMenu.")
		EndIf
	EndIf

	Return critical
EndFunction


Function CheckForBodyMods()
	Int prevBodyClass = maleBodyClass
	If Game.GetModByName("Schlongs of Skyrim.esp") != 255
		maleBodyClass = 1
		Utility.Wait(1.0)
		Main.BuildSchlongList()
	ElseIf (Game.GetModByName("Schlongs of Skyrim - Light.esp") != 255) || (Game.GetModByName("Schlongs of SkyrimSE - Light.esp") != 255)
		maleBodyClass = 2
		numBodies = JsonUtil.StringListCount(jfile, "SOS Light Bodies")
		bodyNames = Utility.CreateStringArray(numBodies, "")
		JsonUtil.StringListSlice(jfile, "SOS Light Bodies", bodyNames, 0)
	ElseIf Game.GetModByName("SAM - Shape Atlas for Men.esp") != 255
		maleBodyClass = 3
	Else  ; esp-less body replacer
		maleBodyClass = 0
		numBodies = JsonUtil.StringListCount(jfile, "Static Bodies")
		bodyNames = Utility.CreateStringArray(numBodies, "")
		JsonUtil.StringListSlice(jfile, "Static Bodies", bodyNames, 0)
	EndIf
	If maleBodyClass != prevBodyClass  ; when body class has changed, reset subtype so it won't be out of range
		maleBody = 0
	EndIf
	If maleBodyClass == 0 || maleBodyClass == 2  ; esp-less, or SOS Light: publish subtype name
		maleBodyName = bodyNames[maleBody]
	EndIf
EndFunction


; --------------------------------------------------------------------
;                        Crosshair targeting
; --------------------------------------------------------------------

Actor Function GetValidCrosshairRef()
	crosshairRef = Game.GetCurrentCrosshairRef() as Actor
	crosshairBase = none
	crosshairName = ""
	If crosshairRef != none
		If crosshairRef.HasKeywordString("ActorTypeNPC")
			crosshairBase = crosshairRef.GetLeveledActorBase()
			If crosshairBase != none
				If crosshairRef.IsChild()
					crosshairRef = none
				Else
					crosshairName = crosshairBase.GetName()
				EndIf
			Else
				crosshairRef = none
			EndIf
		Else
			crosshairRef = none
		EndIf
	EndIf
	Return crosshairRef
EndFunction


; --------------------------------------------------------------------
;                            MCM menu
; --------------------------------------------------------------------

Event OnPageReset(String page)
	If critical
		SetCursorFillMode(TOP_TO_BOTTOM)
		AddTextOption("An essential dependency is missing.", "", OPTION_FLAG_DISABLED)
		AddTextOption("Cumshot will not work correctly.", "", OPTION_FLAG_DISABLED)

	ElseIf page == "" || page == "General"
		SetTitleText("Cumshot " + versionString)
		SetCursorFillMode(TOP_TO_BOTTOM)
		AddHeaderOption("General settings")
		If SexLabInstalled || FlowerGirlsInstalled
			alwaysOID = AddToggleOption("Always show ejaculation", alwaysShowEjac)
		Else
			alwaysOID = AddTextOption("Always show ejaculation", "n/a", OPTION_FLAG_DISABLED)
		EndIf
		triggerKeyOID = AddKeyMapOption("Trigger ejaculation hotkey", triggerKey)
		AddEmptyOption()

		AddHeaderOption("Advanced settings")
		delayOID = AddSliderOption("Ejaculation delay", equipDelay, "{2} seconds")
		debugLvOID = AddMenuOption("Debug messages", debugLvNames[debugMsgLevel])
		reloadJsonKeyOID = AddKeyMapOption("Reload adjustments key", reloadJsonKey)
		resetRngOID = AddTextOption("Reset RNG seeds", "Reset")

		SetCursorPosition(1)  ; right side of the menu

		If !SexLabInstalled && !FlowerGirlsInstalled
			AddHeaderOption("No supported framework installed")
			AddTextOption("Use the hotkey to make characters cum", "", OPTION_FLAG_DISABLED)
			AddEmptyOption()
		Else
			AddHeaderOption("SexLab")
			If SexLabInstalled
				If CS2SexLabSupported.GetValueInt()
					orgasmDetectOID = AddMenuOption("Orgasm detection", detectModeNames[orgasmDetectMode])
					victimsOID = AddToggleOption("Victims ejaculate", victimsEjaculate)
				Else
					AddTextOption("Install and activate CumshotSL.esp", "", OPTION_FLAG_DISABLED)
				EndIf
			Else
				AddTextOption("Not installed", "", OPTION_FLAG_DISABLED)
			EndIf
			AddEmptyOption()
			AddHeaderOption("Flower Girls")
			If FlowerGirlsInstalled
				If CS2FlowerGirlsSupported.GetValueInt()
					stageEventOID = AddToggleOption("Stage event workaround", useStageEvent)
				Else
					AddTextOption("Install and activate CumshotFG.esp", "", OPTION_FLAG_DISABLED)
				EndIf
			Else
				AddTextOption("Not installed", "", OPTION_FLAG_DISABLED)
			EndIf
			AddEmptyOption()
		EndIf

		If ArousedInstalled
			AddHeaderOption("Aroused")
			arousalOID = AddToggleOption("Arousal affects ejaculation", useArousal)
			exposureOID = AddSliderOption("Hotkey use reduces arousal", hotkeyExposure)
		EndIf

	ElseIf page == "Visuals"
		SetCursorFillMode(TOP_TO_BOTTOM)
		ejacModeOID = AddMenuOption("Ejaculation mode", ejacModeNames[ejaculationMode - 1])
		If ejaculationMode != 1  ; only the animated mesh has the drip
			dripOID = AddTextOption("Show final drip", "n/a", OPTION_FLAG_DISABLED)
		ElseIf !niOverrideReqMet  ; and it's always visible without NiOverride
			dripOID = AddToggleOption("Show final drip", True, OPTION_FLAG_DISABLED)
		Else
			dripOID = AddToggleOption("Show final drip", showDrip)
		EndIf
		If ejaculationMode >= 3  ; disable for drops and projectiles, they have triggering capabilities by themselves
			tracerOID = AddToggleOption("Tracer objects", False, OPTION_FLAG_DISABLED)
		Else
			tracerOID = AddToggleOption("Tracer objects", tracerObject)
		EndIf
		AddEmptyOption()

		AddHeaderOption("Actor stats (global)")
		If ejaculationMode == 1  ; animated mesh has only one ejaculation pattern
			amountOID = AddTextOption("Cum amount", "n/a", OPTION_FLAG_DISABLED)
		Else
			amountOID = AddSliderOption("Cum amount", cumAmount, "{2}")
		EndIf
		If ejaculationMode != 3  ; only drop objects mode supports this
			powerOID = AddTextOption("Ejaculation power", "n/a", OPTION_FLAG_DISABLED)
		Else
			powerOID = AddSliderOption("Ejaculation power", ejaculationPower, "{2}")
		EndIf
		If ejaculationMode != 3  ; only drop objects mode supports this
			ratioOID = AddTextOption("Spurt ratio", "n/a", OPTION_FLAG_DISABLED)
		Else
			ratioOID = AddSliderOption("Spurt ratio", spurtRatio, "{2}")
		EndIf
		If (ejaculationMode == 1 && !niOverrideReqMet) || ejaculationMode == 2  ; without NiOverride, the mesh can't be made transparent
			alphaOID = AddTextOption("Cum opacity", "1.00", OPTION_FLAG_DISABLED)
		Else
			alphaOID = AddSliderOption("Cum opacity", cumAlpha, "{2}")
		EndIf
		AddEmptyOption()

		unrealisticOID = AddToggleOption("Allow unrealistic values", allowUnrealistic)
		If ejaculationMode == 1  ; animated mesh has only one ejaculation pattern
			drainingOID = AddToggleOption("Draining and recovery", False, OPTION_FLAG_DISABLED)
		Else
			drainingOID = AddToggleOption("Draining and recovery", draining)
		EndIf

		SetCursorPosition(1)
		If maleBodyClass == 0
			AddHeaderOption("Body / penis type: Mesh replacer")
			bodyOID = AddMenuOption("Body:", bodyNames[maleBody])
		ElseIf maleBodyClass == 1
			AddHeaderOption("Body / penis type: SOS Full")
			bodyOID = AddTextOption("Schlong types are automatically detected", "", OPTION_FLAG_DISABLED)
		ElseIf maleBodyClass == 2
			AddHeaderOption("Body / penis type: SOS Light")
			bodyOID = AddMenuOption("Schlong:", bodyNames[maleBody])
		ElseIf maleBodyClass == 3
			AddHeaderOption("Body / penis type: SAM")
			bodyOID = AddTextOption("Schlong type depends on race", "", OPTION_FLAG_DISABLED)
		EndIf

		; individual actor stats
		SetCursorPosition(9)
		If GetValidCrosshairRef() == None
			crosshairRef = playerRef
			crosshairBase = crosshairRef.GetLeveledActorBase()
			crosshairName = crosshairBase.GetName()
		EndIf
		Main.ClampActorValues(crosshairRef)
		AddHeaderOption(crosshairName)
		Float indValue
		indValue = StorageUtil.GetFloatValue(crosshairRef, "CS2CumAmount", -1.0)
		If ejaculationMode == 1  ; animated mesh has only one ejaculation pattern
			indAmountOID = AddTextOption("Cum amount", "n/a", OPTION_FLAG_DISABLED)
		ElseIf indValue == -1.0  ; no value set on this actor
			indAmountOID = AddTextOption("Cum amount", "(use global)")
		Else
			indAmountOID = AddSliderOption("Cum amount", indValue, "{2}")
		EndIf
		indValue = StorageUtil.GetFloatValue(crosshairRef, "CS2EjaculationPower", -1.0)
		If ejaculationMode != 3  ; only drop objects mode supports this
			indPowerOID = AddTextOption("Ejaculation power", "n/a", OPTION_FLAG_DISABLED)
		ElseIf indValue == -1.0  ; no value set on this actor
			indPowerOID = AddTextOption("Ejaculation power", "(use global)")
		Else
			indPowerOID = AddSliderOption("Ejaculation power", indValue, "{2}")
		EndIf
		indValue = StorageUtil.GetFloatValue(crosshairRef, "CS2SpurtRatio", -1.0)
		If ejaculationMode != 3  ; only drop objects mode supports this
			indRatioOID = AddTextOption("Spurt ratio", "n/a", OPTION_FLAG_DISABLED)
		ElseIf indValue == -1.0  ; no value set on this actor
			indRatioOID = AddTextOption("Spurt ratio", "(use global)")
		Else
			indRatioOID = AddSliderOption("Spurt ratio", indValue, "{2}")
		EndIf
		indValue = StorageUtil.GetFloatValue(crosshairRef, "CS2CumOpacity", -1.0)
		If (ejaculationMode == 1 && !niOverrideReqMet) || ejaculationMode == 2  ; without NiOverride, the mesh can't be made transparent
			indAlphaOID = AddTextOption("Cum opacity", "1.00", OPTION_FLAG_DISABLED)
		ElseIf indValue == -1.0  ; no value set on this actor
			indAlphaOID = AddTextOption("Cum opacity", "(use global)")
		Else
			indAlphaOID = AddSliderOption("Cum opacity", indValue, "{2}")
		EndIf
		If crosshairRef == playerRef
			AddTextOption("For NPCs: target them with the crosshair", "", OPTION_FLAG_DISABLED)
		Else
			AddTextOption("For player: point crosshair to empty space", "", OPTION_FLAG_DISABLED)
		EndIf

	ElseIf page == "Genital data"
		SetCursorFillMode(TOP_TO_BOTTOM)
		If genShowingNPC && GetValidCrosshairRef()
			genActor = crosshairRef
			genActorBase = crosshairBase
			genActorOID = AddTextOption("NPC", crosshairName)
		Else
			genShowingNPC = False
			genActor = playerRef
			genActorBase = playerRef.GetActorBase()
			genActorOID = AddTextOption("Player", genActorBase.GetName())
		EndIf
		genIsFemale = (genActorBase.GetSex() == 1)
		genRace = genActor.GetRace()
		If genIsFemale
			AddTextOption("(Female " + genRace.GetName() + ")", "", OPTION_FLAG_DISABLED)
		Else
			AddTextOption("(Male " + genRace.GetName() + ")", "", OPTION_FLAG_DISABLED)
		EndIf

		AddHeaderOption("")
		Main.IdentifyGenitals(genActor)

		If genType == 0
			AddTextOption("Slot 52 item", "(None)", OPTION_FLAG_DISABLED)
			If genIsFemale
				AddEmptyOption()
				genActiveOID = AddToggleOption("Body can ejaculate", genActive)
			Else
				If maleBodyClass == 0 || maleBodyClass == 2  ; SOS Light
					AddTextOption("(Default body: " + maleBodyName + ")", "")
				ElseIf maleBodyClass == 3  ; SAM
					AddTextOption("(Default body: SAM)", "")
				EndIf
				genActiveOID = AddToggleOption("Has special body override", genActive)
			EndIf
		ElseIf genType == 1
			AddTextOption("Slot 52 item", genForm.GetName(), OPTION_FLAG_DISABLED)
			AddTextOption("(SOS addon)", "", OPTION_FLAG_DISABLED)
			If genIsFemale || !genMalesAlways
				genActiveOID = AddToggleOption("Addon can ejaculate", genActive)
			Else
				genActiveOID = AddToggleOption("Addon has own adjustments", genActive)
			EndIf
		ElseIf genType == 2
			AddTextOption("Slot 52/60 item", genForm.GetName(), OPTION_FLAG_DISABLED)
			AddTextOption("(equipable item)", "", OPTION_FLAG_DISABLED)
			genActiveOID = AddToggleOption("Item can ejaculate", genActive)
		EndIf

		If genActive
			genKeyOID = AddInputOption("Entry:", genKey)
			If genType == 0
				If genIsFemale
					genAppliesToNames[1] = "This character's race (F)"
				Else
					genAppliesToNames[1] = "This character's race (M)"
				EndIf
				genappliesToOID = AddMenuOption("Applies to", genAppliesToNames[genIsRacial as Int])
			ElseIf genType == 1
				genIsRacialOID = AddToggleOption("Is racial variant", genIsRacial)
			EndIf
			ShowTransformSettings(True)
		ElseIf genMalesAlways && !genIsFemale

			ShowTransformSettings(False)
		EndIf

		SetCursorPosition(20)
		genMalesAlwaysOID = AddToggleOption("Males can always ejaculate", genMalesAlways)

	;/ElseIf page == "Animations (SexLab)"
		animOID = Utility.CreateIntArray(numRegAnimsSL)
		SetCursorFillMode(LEFT_TO_RIGHT)
		numAnimPages = (numRegAnimsSL - 1) / animsPerPage + 1
		If numAnimPages == 1
			animPageDummyOID = AddTextOption("Viewing page:", "1 / 1")
		Else
			animPageOID = AddSliderOption("Viewing page:", curAnimPage, "{0} / " + numAnimPages)
		EndIf
		slActionsOID = AddMenuOption("Actions", "Choose...")
		AddHeaderOption("")
		AddHeaderOption("")
		If numRegAnimsSL == 0
			SetCursorPosition(4)
			AddTextOption("No animations registered", "", OPTION_FLAG_DISABLED)
			Return
		EndIf
		Int i = (curAnimPage - 1) * animsPerPage
		While i < numRegAnimsSL && i < curAnimPage * animsPerPage
			animOID[i] = AddTextOption(animNameSL[i], GetEjacCode(animPosCountSL[i], animValSL[i]))
			i += 1
		EndWhile/;
	EndIf
EndEvent

Function ShowTransformSettings(Bool editable)
	Int flags = OPTION_FLAG_NONE
	If !editable
		flags = OPTION_FLAG_DISABLED
	EndIf
	SetCursorPosition(1)
	If genKeepWDVOnReset  ; don't immediately hide the weight 100 values again on page reset after having turned them on
		genKeepWDVOnReset = False
	Else  ; separate weight 0 and 100 values are shown when they are different
		genWeightDependent = (genMove0[0] != genMove100[0] || genMove0[1] != genMove100[1] || genMove0[2] != genMove100[2])
	EndIf

	genWeightDependentOID = AddToggleOption("Weight dependent values", genWeightDependent, flags)
	AddEmptyOption()
	genRotateOID = AddSliderOption("Rotation X", genRotate[2], "{0}", flags)
	AddEmptyOption()
	If genWeightDependent
		genMove0xOID = AddSliderOption("Adjustment X (weight 0)", genMove0[0], "{1}", flags)
		genMove0yOID = AddSliderOption("Adjustment Y (weight 0)", genMove0[1], "{1}", flags)
		genMove0zOID = AddSliderOption("Adjustment Z (weight 0)", genMove0[2], "{1}", flags)
		AddEmptyOption()
		genMove100xOID = AddSliderOption("Adjustment X (weight 100)", genMove100[0], "{1}", flags)
		genMove100yOID = AddSliderOption("Adjustment Y (weight 100)", genMove100[1], "{1}", flags)
		genMove100zOID = AddSliderOption("Adjustment Z (weight 100)", genMove100[2], "{1}", flags)
	Else
		genMove0xOID = AddSliderOption("Adjustment X", genMove0[0], "{1}", flags)
		genMove0yOID = AddSliderOption("Adjustment Y", genMove0[1], "{1}", flags)
		genMove0zOID = AddSliderOption("Adjustment Z", genMove0[2], "{1}", flags)
	EndIf
EndFunction

Event OnOptionSelect(Int option)
	If CurrentPage == "" || CurrentPage == "General"
		If option == alwaysOID
			alwaysShowEjac = !alwaysShowEjac
			SetToggleOptionValue(alwaysOID, alwaysShowEjac)
		ElseIf option == resetRngOID
			Main.ResetQRand()
		ElseIf option == victimsOID
			victimsEjaculate = !victimsEjaculate
			SetToggleOptionValue(victimsOID, victimsEjaculate)
		ElseIf option == stageEventOID
			useStageEvent = !useStageEvent
			SetToggleOptionValue(stageEventOID, useStageEvent)
		ElseIf option == arousalOID
			useArousal = !useArousal
			SetToggleOptionValue(arousalOID, useArousal)
		EndIf

	ElseIf CurrentPage == "Visuals"
		If option == dripOID
			showDrip = !showDrip
			SetToggleOptionValue(dripOID, showDrip)
		ElseIf option == tracerOID
			tracerObject = !tracerObject
			SetToggleOptionValue(tracerOID, tracerObject)
		ElseIf option == unrealisticOID
			If allowUnrealistic
				ClampAndUpdateDisplayed()
			EndIf
			allowUnrealistic = !allowUnrealistic
			SetToggleOptionValue(unrealisticOID, allowUnrealistic, False)
		ElseIf option == drainingOID
			draining = !draining
			SetToggleOptionValue(drainingOID, draining)
		; next four cases: clicked on an individual setting that shows "(use global)"
		ElseIf option == indAmountOID
			StorageUtil.SetFloatValue(crosshairRef, "CS2CumAmount", cumAmount)
			ForcePageReset()
		ElseIf option == indPowerOID
			StorageUtil.SetFloatValue(crosshairRef, "CS2EjaculationPower", ejaculationPower)
			ForcePageReset()
		ElseIf option == indRatioOID
			StorageUtil.SetFloatValue(crosshairRef, "CS2SpurtRatio", spurtRatio)
			ForcePageReset()
		ElseIf option == indAlphaOID
			StorageUtil.SetFloatValue(crosshairRef, "CS2CumOpacity", cumAlpha)
			ForcePageReset()
		EndIf

	ElseIf CurrentPage == "Genital data"
		If option == genActorOID
			If genShowingNPC
				genShowingNPC = False
				ForcePageReset()
			ElseIf GetValidCrosshairRef()
				genShowingNPC = True
				ForcePageReset()
			Else
				ShowMessage("No valid NPC is under the crosshair.", False)
			EndIf
		ElseIf option == genActiveOID
			genActive = !genActive
			If genActive  ; adding genital data
				If genType == 0  ; body with integrated penis
					genForm = genActorBase
					genKey = Main.CreateUniqueKey(genActorBase.GetName())
					Main.AddDatabaseEntry(genType, genForm, genKey, genForm, genIsFemale)
				Else
					genKey = Main.CreateUniqueKey(genForm.GetName())
					Main.AddDatabaseEntry(genType, genForm, genKey)
				EndIf
			Else  ; removing genital data
				If genType == 0
					Main.RemoveDatabaseEntry(genType, genKey, genForm, genForFemale)
				Else
					Main.RemoveDatabaseEntry(genType, genKey)
				EndIf
			EndIf
			ForcePageReset()
		ElseIf option == genIsRacialOID
			genIsRacial = !genIsRacial
			If genIsRacial
				Main.AddDatabaseEntry(genType, genForm, genKey, genRace)
			Else
				Main.RemoveDatabaseEntry(genType, genKey, genRace)
			EndIf
			ForcePageReset()
		ElseIf option == genMalesAlwaysOID
			genMalesAlways = !genMalesAlways
			If genIsFemale
				SetToggleOptionValue(genMalesAlwaysOID, genMalesAlways)
			Else
				ForcePageReset()
			EndIf
		ElseIf option == genWeightDependentOID
			genWeightDependent = !genWeightDependent
			If !genWeightDependent  ; separate weight values have been switched off - copy weight0 values to weight100
				genMove100[0] = genMove0[0]
				genMove100[1] = genMove0[1]
				genMove100[2] = genMove0[2]
				JsonUtil.FloatListSet(jfile, genKey, 3, genMove0[0])
				JsonUtil.FloatListSet(jfile, genKey, 4, genMove0[1])
				JsonUtil.FloatListSet(jfile, genKey, 5, genMove0[2])
				JsonUtil.Save(jfile, minify = True)
			EndIf
			genKeepWDVOnReset = True
			ForcePageReset()
		EndIf
		
	;/ElseIf CurrentPage == "Animations (SexLab)"
		If option == animPageDummyOID
			; nothing, this is the text option that says "Viewing Page: 1 / 1"
		Else  ; the actual entries in the list
			Int i = animOID.Find(option)
			animValSL[i] = animValSL[i] + 1
			If animValSL[i] >= Math.LeftShift(1, animPosCountSL[i])
				animValSL[i] = -1
				StorageUtil.UnsetIntValue(CS2EjaculationRulesSL, animRegSL[i])
			Else
				StorageUtil.SetIntValue(CS2EjaculationRulesSL, animRegSL[i], animValSL[i])
			EndIf
			SetTextOptionValue(option, GetEjacCode(animPosCountSL[i], animValSL[i]))			
		EndIf/;
	EndIf
EndEvent

Event OnOptionSliderOpen(Int sOption)
	If CurrentPage == "" || CurrentPage == "General"
		If sOption == delayOID
			SetSliderDialogStartValue(equipDelay)
			SetSliderDialogDefaultValue(0.1)
			SetSliderDialogRange(0.0, 0.75)
			SetSliderDialogInterval(0.05)
		ElseIf sOption == exposureOID
			SetSliderDialogStartValue(hotkeyExposure)
			SetSliderDialogDefaultValue(0.0)
			SetSliderDialogRange(0.0, 100.0)
			SetSliderDialogInterval(1.0)
		EndIf

	ElseIf CurrentPage == "Visuals"
		If sOption == amountOID
			SetSliderDialogStartValue(cumAmount)
			SetSliderDialogDefaultValue(5.0)
			If allowUnrealistic
				SetSliderDialogRange(0.2, 50.0)
			Else
				SetSliderDialogRange(0.2, 15.0)
			EndIf
			SetSliderDialogInterval(0.1)
		ElseIf sOption == powerOID
			SetSliderDialogStartValue(ejaculationPower)
			SetSliderDialogDefaultValue(1.0)
			If allowUnrealistic
				SetSliderDialogRange(0.1, 10.0)
			Else
				SetSliderDialogRange(0.1, 2.0)
			EndIf
			SetSliderDialogInterval(0.05)
		ElseIf sOption == ratioOID
			SetSliderDialogStartValue(spurtRatio)
			SetSliderDialogDefaultValue(4.0)
			If allowUnrealistic
				SetSliderDialogRange(1.0, 25.0)
			Else
				SetSliderDialogRange(1.0, 10.0)
			EndIf
			SetSliderDialogInterval(0.1)
		ElseIf sOption == alphaOID
			SetSliderDialogStartValue(cumAlpha)
			SetSliderDialogDefaultValue(1.0)
			SetSliderDialogRange(0.0, 1.0)
			SetSliderDialogInterval(0.01)
		ElseIf sOption == indAmountOID
			SetSliderDialogStartValue(StorageUtil.GetFloatValue(crosshairRef, "CS2CumAmount", cumAmount))
			SetSliderDialogDefaultValue(5.0)
			If allowUnrealistic
				SetSliderDialogRange(0.2, 50.0)
			Else
				SetSliderDialogRange(0.2, 15.0)
			EndIf
			SetSliderDialogInterval(0.1)
		ElseIf sOption == indPowerOID
			SetSliderDialogStartValue(StorageUtil.GetFloatValue(crosshairRef, "CS2EjaculationPower", ejaculationPower))
			SetSliderDialogDefaultValue(1.0)
			If allowUnrealistic
				SetSliderDialogRange(0.1, 10.0)
			Else
				SetSliderDialogRange(0.1, 2.0)
			EndIf
			SetSliderDialogInterval(0.05)
		ElseIf sOption == indRatioOID
			SetSliderDialogStartValue(StorageUtil.GetFloatValue(crosshairRef, "CS2SpurtRatio", spurtRatio))
			SetSliderDialogDefaultValue(4.0)
			If allowUnrealistic
				SetSliderDialogRange(1.0, 25.0)
			Else
				SetSliderDialogRange(1.0, 10.0)
			EndIf
			SetSliderDialogInterval(0.1)
		ElseIf sOption == indAlphaOID
			SetSliderDialogStartValue(StorageUtil.GetFloatValue(crosshairRef, "CS2CumOpacity", cumAlpha))
			SetSliderDialogDefaultValue(1.0)
			SetSliderDialogRange(0.0, 1.0)
			SetSliderDialogInterval(0.01)
		EndIf

	ElseIf CurrentPage == "Genital data"
		If sOption == genRotateOID
			SetSliderDialogStartValue(genRotate[2])
			SetSliderDialogDefaultValue(JsonUtil.FloatListGet(jfile, GetDefaultKey(), 8))
			SetSliderDialogRange(-90.0, 90.0)
			SetSliderDialogInterval(1.0)
		ElseIf sOption == genMove0xOID
			SetSliderDialogStartValue(genMove0[0])
			SetSliderDialogDefaultValue(JsonUtil.FloatListGet(jfile, GetDefaultKey(), 0))
			SetSliderDialogRange(-10.0, 10.0)
			SetSliderDialogInterval(0.1)
		ElseIf sOption == genMove0yOID
			SetSliderDialogStartValue(genMove0[1])
			SetSliderDialogDefaultValue(JsonUtil.FloatListGet(jfile, GetDefaultKey(), 1))
			SetSliderDialogRange(-10.0, 30.0)
			SetSliderDialogInterval(0.1)
		ElseIf sOption == genMove0zOID
			SetSliderDialogStartValue(genMove0[2])
			SetSliderDialogDefaultValue(JsonUtil.FloatListGet(jfile, GetDefaultKey(), 2))
			SetSliderDialogRange(-10.0, 20.0)
			SetSliderDialogInterval(0.1)
		ElseIf sOption == genMove100xOID
			SetSliderDialogStartValue(genMove100[0])
			SetSliderDialogDefaultValue(JsonUtil.FloatListGet(jfile, GetDefaultKey(), 3))
			SetSliderDialogRange(-10.0, 10.0)
			SetSliderDialogInterval(0.1)
		ElseIf sOption == genMove100yOID
			SetSliderDialogStartValue(genMove100[1])
			SetSliderDialogDefaultValue(JsonUtil.FloatListGet(jfile, GetDefaultKey(), 4))
			SetSliderDialogRange(-10.0, 30.0)
			SetSliderDialogInterval(0.1)
		ElseIf sOption == genMove100zOID
			SetSliderDialogStartValue(genMove100[2])
			SetSliderDialogDefaultValue(JsonUtil.FloatListGet(jfile, GetDefaultKey(), 5))
			SetSliderDialogRange(-10.0, 20.0)
			SetSliderDialogInterval(0.1)
		EndIf

	;/ElseIf CurrentPage == "Animations (SexLab)"
		If sOption == animPageOID
			SetSliderDialogStartValue(curAnimPage)
			SetSliderDialogDefaultValue(1)
			SetSliderDialogRange(1, numAnimPages)
			SetSliderDialogInterval(1)
		EndIf/;
	EndIf
EndEvent

Event OnOptionSliderAccept(Int sOption, Float value)
	If CurrentPage == "" || CurrentPage == "General"
		If sOption == delayOID
			equipDelay = value
			SetSliderOptionValue(delayOID, equipDelay, "{2} seconds")
		ElseIf sOption == exposureOID
			hotkeyExposure = value as Int
			SetSliderOptionValue(exposureOID, hotkeyExposure)
		EndIf

	ElseIf CurrentPage == "Visuals"
		If sOption == amountOID
			cumAmount = value
			SetSliderOptionValue(amountOID, cumAmount, "{2}")
		ElseIf sOption == powerOID
			ejaculationPower = value
			SetSliderOptionValue(powerOID, ejaculationPower, "{2}")
		ElseIf sOption == ratioOID
			spurtRatio = value
			SetSliderOptionValue(ratioOID, spurtRatio, "{2}")
		ElseIf sOption == alphaOID
			cumAlpha = value
			SetSliderOptionValue(alphaOID, cumAlpha, "{2}")
		ElseIf sOption == indAmountOID
			StorageUtil.SetFloatValue(crosshairRef, "CS2CumAmount", value)
			SetSliderOptionValue(indAmountOID, value, "{2}")
		ElseIf sOption == indPowerOID
			StorageUtil.SetFloatValue(crosshairRef, "CS2EjaculationPower", value)
			SetSliderOptionValue(indPowerOID, value, "{2}")
		ElseIf sOption == indRatioOID
			StorageUtil.SetFloatValue(crosshairRef, "CS2SpurtRatio", value)
			SetSliderOptionValue(indRatioOID, value, "{2}")
		ElseIf sOption == indAlphaOID
			StorageUtil.SetFloatValue(crosshairRef, "CS2CumOpacity", value)
			SetSliderOptionValue(indAlphaOID, value, "{2}")
		EndIf

	ElseIf CurrentPage == "Genital data"
		If sOption == genRotateOID
			genRotate[2] = value
			JsonUtil.FloatListSet(jfile, genKey, 8, value)
			SetSliderOptionValue(genRotateOID, value, "{0}")
		ElseIf sOption == genMove0xOID
			genMove0[0] = value
			JsonUtil.FloatListSet(jfile, genKey, 0, value)
			SetSliderOptionValue(genMove0xOID, value, "{1}")
			If !genWeightDependent
				genMove100[0] = value
				JsonUtil.FloatListSet(jfile, genKey, 3, value)
			EndIf
		ElseIf sOption == genMove0yOID
			genMove0[1] = value
			JsonUtil.FloatListSet(jfile, genKey, 1, value)
			SetSliderOptionValue(genMove0yOID, value, "{1}")
			If !genWeightDependent
				genMove100[1] = value
				JsonUtil.FloatListSet(jfile, genKey, 4, value)
			EndIf
		ElseIf sOption == genMove0zOID
			genMove0[2] = value
			JsonUtil.FloatListSet(jfile, genKey, 2, value)
			SetSliderOptionValue(genMove0zOID, value, "{1}")
			If !genWeightDependent
				genMove100[2] = value
				JsonUtil.FloatListSet(jfile, genKey, 5, value)
			EndIf
		ElseIf sOption == genMove100xOID
			genMove100[0] = value
			JsonUtil.FloatListSet(jfile, genKey, 3, value)
			SetSliderOptionValue(genMove100xOID, value, "{1}")
		ElseIf sOption == genMove100yOID
			genMove100[1] = value
			JsonUtil.FloatListSet(jfile, genKey, 4, value)
			SetSliderOptionValue(genMove100yOID, value, "{1}")
		ElseIf sOption == genMove100zOID
			genMove100[2] = value
			JsonUtil.FloatListSet(jfile, genKey, 5, value)
			SetSliderOptionValue(genMove100zOID, value, "{1}")
		EndIf
		JsonUtil.Save(jfile, minify = True)
		
	;/ElseIf CurrentPage == "Animations (SexLab)"
		If sOption == animPageOID
			curAnimPage = value as Int
			ForcePageReset()
		EndIf/;
	EndIf
EndEvent

Event OnOptionKeyMapChange(Int kOption, Int keyCode, String conflictControl, String conflictName)
	Bool continue = True
	If (conflictControl != "")
		String msg
		If (conflictName != "")
			msg = "This key is already mapped to:\n\"" + conflictControl + "\"\n(" + conflictName + ")\n\nAre you sure you want to continue?"
		Else
			msg = "This key is already mapped to:\n\"" + conflictControl + "\"\n\nAre you sure you want to continue?"
		EndIf
		continue = ShowMessage(msg, True, "Yes", "No")
	EndIf
	If continue && kOption == triggerKeyOID
		If triggerKey > 0
			Main.UnregisterForKey(triggerKey)
		EndIf
		triggerKey = keyCode
		SetKeyMapOptionValue(triggerKeyOID, triggerKey)
		Main.RegisterForKey(triggerKey)
	ElseIf continue && kOption == reloadJsonKeyOID
		If reloadJsonKey > 0
			Main.UnregisterForKey(reloadJsonKey)
		EndIf
		reloadJsonKey = keyCode
		SetKeyMapOptionValue(reloadJsonKeyOID, reloadJsonKey)
		Main.RegisterForKey(reloadJsonKey)
	EndIf
EndEvent

String Function GetCustomControl(Int keyCode)
	If (keyCode == triggerKey)
		Return "Trigger ejaculation"
	ElseIf (keyCode == reloadJsonKey)
		Return "Reload adjustments"
	Else
		Return ""
	EndIf
EndFunction

Event OnOptionMenuOpen(Int mOption)
	SetMenuDialogDefaultIndex(0)  ; it's the same for all the menus
	If CurrentPage == "" || CurrentPage == "General"
		If mOption == orgasmDetectOID
			SetMenuDialogOptions(detectModeNames)
			SetMenuDialogStartIndex(orgasmDetectMode)
		ElseIf mOption == debugLvOID
			SetMenuDialogOptions(debugLvNames)
			SetMenuDialogStartIndex(debugMsgLevel)
		EndIf

	ElseIf CurrentPage == "Visuals"
		If mOption == bodyOID
			SetMenuDialogOptions(bodyNames)
			SetMenuDialogStartIndex(maleBody)
		ElseIf mOption == ejacModeOID
			SetMenuDialogOptions(ejacModeNames)
			SetMenuDialogStartIndex(ejaculationMode - 1)
		EndIf

	ElseIf CurrentPage == "Genital data"
		If mOption == genappliesToOID
			SetMenuDialogOptions(genAppliesToNames)
			SetMenuDialogStartIndex(genIsRacial as Int)
		EndIf

	;/ElseIf CurrentPage == "Animations (SexLab)"
		If mOption == slActionsOID
			SetMenuDialogOptions(slActionsNames)
			SetMenuDialogStartIndex(0)
		EndIf/;
	EndIf
EndEvent

Event OnOptionMenuAccept(Int mOption, Int index)
	If CurrentPage == "" || CurrentPage == "General"
		If mOption == orgasmDetectOID
			orgasmDetectMode = index
			SetMenuOptionValue(orgasmDetectOID, detectModeNames[index])
		ElseIf mOption == debugLvOID
			debugMsgLevel = index
			Main.debugMsgLevel = index  ; copy to a property in CS2GameScript for faster access
			SetMenuOptionValue(debugLvOID, debugLvNames[index])
		EndIf

	ElseIf CurrentPage == "Visuals"
		If mOption == bodyOID
			maleBody = index
			maleBodyName = bodyNames[index]
			SetMenuOptionValue(bodyOID, bodyNames[index])
		ElseIf mOption == ejacModeOID
			ejaculationMode = index + 1
			Main.SelectArmorToEquip(ejaculationMode)
			SetMenuOptionValue(ejacModeOID, ejacModeNames[index], True)
			ForcePageReset()  ; update all the options that may have changed their availability status
		EndIf

	ElseIf CurrentPage == "Genital data"
		If mOption == genappliesToOID
			If index == (genIsRacial as Int)
				Return  ; nothing has actually changed
			EndIf
			If index == 0  ; changed from race to ActorBase
				Bool keep = ShowMessage("Keep the entry for the actor's race?", True, "Yes", "No")
				Main.SwitchDatabaseBodyEntry(genKey, genActorBase, keepRaceEntry = keep)
			Else  ; changed from ActorBase to race
				Main.SwitchDatabaseBodyEntry(genKey, genRace, genIsFemale)
			EndIf
			ForcePageReset()
		EndIf

	;/ElseIf CurrentPage == "Animations (SexLab)"
		If mOption == slActionsOID
			If index == 1  ; Explanation
				ExplainSLAnimsTab()
			ElseIf index == 2 || index == 3  ; Rebuild animation list
				If index == 3
					defaultRulesSet = False  ; force reloading rules from files
					forceClearRules = True  ; and clear all changed rules that have no defaults and haven't been saved
				EndIf
				; Request CS2SexLabScript to run RebuildAnimListSL().
				; It's done this way because CS2ConfigScript needs to be agnostic of SexLab classes, or scripts that contain them.
				Int handle = ModEvent.Create("CS2RequestRebuildSL")
				If handle
					ModEvent.Send(handle)
					rebuilding = True
					; now wait for RebuildAnimListSL() to finish and reset the flag
					While rebuilding
						Utility.WaitMenuMode(0.25)
					EndWhile
				EndIf
				ForcePageReset()
			ElseIf index == 4  ; Save custom rules to file
				; Request CS2SexLabScript to run SaveCustomRules(), same reason as above.
				Int handle = ModEvent.Create("CS2RequestSaveCustomSL")
				If handle
					ModEvent.Send(handle)
				EndIf
			EndIf
		EndIf/;
	EndIf
EndEvent

Event OnOptionInputOpen(Int option)
	If option == genKeyOID
		String keyToEdit = genKey
		Int atPos = StringUtil.Find(genKey, "@")
		If atPos >= 0  ; there's a "@" inside the full key
			keyToEdit = StringUtil.Substring(genKey, 0, atPos)
		EndIf
		SetInputDialogStartText(keyToEdit)
	EndIf
EndEvent

Event OnOptionInputAccept(Int option, String newKey)
	If option == genKeyOID
		Int error = Main.RenameDatabaseEntry(genType, genForm, genKey, newKey)
		If error == -1
			ShowMessage("This name already exists. Each entry must have a unique name.", False)
			Return
		ElseIf error == -2
			ShowMessage("Entries must not have the character '@' in their name. This character is used to mark racial and gender variants. If you're editing such an entry, it will be automatically appended.", False)
			Return
		EndIf
		ForcePageReset()
	EndIf
EndEvent

Event OnOptionDefault(Int option)
	If CurrentPage == "" || CurrentPage == "General"
		If option == alwaysOID
			alwaysShowEjac = False
			SetToggleOptionValue(alwaysOID, alwaysShowEjac)
		ElseIf option == triggerKeyOID
			If triggerKey > 0
				Main.UnregisterForKey(triggerKey)
			EndIf
			triggerKey = -1  ; unbind
			SetKeyMapOptionValue(triggerKeyOID, -1)
		ElseIf option == delayOID
			equipDelay = 0.1
			SetSliderOptionValue(delayOID, equipDelay, "{2} seconds")
		ElseIf option == debugLvOID
			debugMsgLevel = 0
			SetMenuOptionValue(debugLvOID, debugLvNames[0])
		ElseIf option == reloadJsonKeyOID
			If reloadJsonKey > 0
				Main.UnregisterForKey(reloadJsonKey)
			EndIf
			reloadJsonKey = -1  ; unbind
			SetKeyMapOptionValue(reloadJsonKeyOID, -1)
		ElseIf option == orgasmDetectOID
			orgasmDetectMode = 0
			SetMenuOptionValue(orgasmDetectOID, detectModeNames[0])
		ElseIf option == victimsOID
			victimsEjaculate = False
			SetToggleOptionValue(victimsOID, victimsEjaculate)
		ElseIf option == stageEventOID
			useStageEvent = True
			SetToggleOptionValue(stageEventOID, useStageEvent)
		ElseIf option == arousalOID
			useArousal = False
			SetToggleOptionValue(arousalOID, useArousal)
		ElseIf option == exposureOID
			hotkeyExposure = 0
			SetSliderOptionValue(exposureOID, hotkeyExposure)
		EndIf

	ElseIf CurrentPage == "Visuals"
		If option == bodyOID
			maleBody = 0
			maleBodyName = bodyNames[0]
			SetMenuOptionValue(bodyOID, bodyNames[0])
		ElseIf option == ejacModeOID
			ejaculationMode == 1
			ForcePageReset()  ; update all the options that may have changed their availability status
		ElseIf option == dripOID
			showDrip = True
			SetToggleOptionValue(dripOID, showDrip)
		ElseIf option == tracerOID
			tracerObject = False
			SetToggleOptionValue(tracerOID, tracerObject)
		ElseIf option == amountOID
			cumAmount = 5.0
			SetSliderOptionValue(amountOID, cumAmount, "{2}")
		ElseIf option == powerOID
			ejaculationPower = 1.0
			SetSliderOptionValue(powerOID, ejaculationPower, "{2}")
		ElseIf option == ratioOID
			spurtRatio = 4.0
			SetSliderOptionValue(ratioOID, spurtRatio, "{2}")
		ElseIf option == alphaOID
			cumAlpha = 1.0
			SetSliderOptionValue(alphaOID, cumAlpha, "{2}")
		ElseIf option == indAmountOID
			If StorageUtil.HasFloatValue(crosshairRef, "CS2CumAmount")
				StorageUtil.UnsetFloatValue(crosshairRef, "CS2CumAmount")
				ForcePageReset()
			EndIf
		ElseIf option == indPowerOID
			If StorageUtil.HasFloatValue(crosshairRef, "CS2EjaculationPower")
				StorageUtil.UnsetFloatValue(crosshairRef, "CS2EjaculationPower")
				ForcePageReset()
			EndIf
		ElseIf option == indRatioOID
			If StorageUtil.HasFloatValue(crosshairRef, "CS2SpurtRatio")
				StorageUtil.UnsetFloatValue(crosshairRef, "CS2SpurtRatio")
				ForcePageReset()
			EndIf
		ElseIf option == indAlphaOID
			If StorageUtil.HasFloatValue(crosshairRef, "CS2CumOpacity")
				StorageUtil.UnsetFloatValue(crosshairRef, "CS2CumOpacity")
				ForcePageReset()
			EndIf
		ElseIf option == unrealisticOID
			If allowUnrealistic
				ClampAndUpdateDisplayed()
			EndIf
			allowUnrealistic = False
			SetToggleOptionValue(unrealisticOID, allowUnrealistic, False)
		ElseIf option == drainingOID
			draining = False
			SetToggleOptionValue(drainingOID, draining)
		EndIf

	ElseIf CurrentPage == "Genital data"
		If option == genMalesAlwaysOID
			genMalesAlways = True
			If genIsFemale
				SetToggleOptionValue(genMalesAlwaysOID, genMalesAlways)
			Else
				ForcePageReset()
			EndIf
		Else  ; adjustment values
			If option == genRotateOID
				genRotate[2] = JsonUtil.FloatListGet(jfile, GetDefaultKey(), 8)
				JsonUtil.FloatListSet(jfile, genKey, 8, genRotate[2])
				SetSliderOptionValue(genRotateOID, genRotate[2], "{0}")
			ElseIf option == genMove0xOID
				genMove0[0] = JsonUtil.FloatListGet(jfile, GetDefaultKey(), 0)
				JsonUtil.FloatListSet(jfile, genKey, 0, genMove0[0])
				SetSliderOptionValue(genMove0xOID, genMove0[0], "{1}")
				If !genWeightDependent
					genMove100[0] = genMove0[0]
					JsonUtil.FloatListSet(jfile, genKey, 3, genMove100[0])
				EndIf
			ElseIf option == genMove0yOID
				genMove0[1] = JsonUtil.FloatListGet(jfile, GetDefaultKey(), 1)
				JsonUtil.FloatListSet(jfile, genKey, 1, genMove0[1])
				SetSliderOptionValue(genMove0yOID, genMove0[1], "{1}")
				If !genWeightDependent
					genMove100[1] = genMove0[1]
					JsonUtil.FloatListSet(jfile, genKey, 4, genMove100[1])
				EndIf
			ElseIf option == genMove0zOID
				genMove0[2] = JsonUtil.FloatListGet(jfile, GetDefaultKey(), 2)
				JsonUtil.FloatListSet(jfile, genKey, 2, genMove0[2])
				SetSliderOptionValue(genMove0zOID, genMove0[2], "{1}")
				If !genWeightDependent
					genMove100[2] = genMove0[2]
					JsonUtil.FloatListSet(jfile, genKey, 5, genMove100[2])
				EndIf
			ElseIf option == genMove100xOID
				genMove100[0] = JsonUtil.FloatListGet(jfile, GetDefaultKey(), 3)
				JsonUtil.FloatListSet(jfile, genKey, 3, genMove100[0])
				SetSliderOptionValue(genMove100xOID, genMove100[0], "{1}")
			ElseIf option == genMove100yOID
				genMove100[1] = JsonUtil.FloatListGet(jfile, GetDefaultKey(), 4)
				JsonUtil.FloatListSet(jfile, genKey, 4, genMove100[1])
				SetSliderOptionValue(genMove100yOID, genMove100[1], "{1}")
			ElseIf option == genMove100zOID
				genMove100[2] = JsonUtil.FloatListGet(jfile, GetDefaultKey(), 5)
				JsonUtil.FloatListSet(jfile, genKey, 5, genMove100[2])
				SetSliderOptionValue(genMove100zOID, genMove100[2], "{1}")
			EndIf
			JsonUtil.Save(jfile, minify = True)
		EndIf

	;/ElseIf CurrentPage == "Animations (SexLab)"
		If option == animPageOID
			curAnimPage += 1
			If curAnimPage > numAnimPages
				curAnimPage = 1
			EndIf
			ForcePageReset()
		ElseIf option != animPageDummyOID && option != slActionsOID
			Int i = animOID.Find(option)
			animValSL[i] = -1
			StorageUtil.UnsetIntValue(CS2EjaculationRulesSL, animRegSL[i])
			SetTextOptionValue(option, GetEjacCode(animPosCountSL[i], animValSL[i]))									
		EndIf/;
	EndIf
EndEvent

Event OnOptionHighlight(Int option)
	If CurrentPage == "" || CurrentPage == "General"
		If option == alwaysOID
			SetInfoText("If checked, ejaculations will be displayed for all male actors in every animation.\nThis overrides the settings for individual animations.")
		ElseIf option == triggerKeyOID
			SetInfoText("Pressing this key makes the player character ejaculate. When holding Shift at the same time, the NPC under the crosshair ejaculates.\nCAUTION: This might cause problems when the key is pressed at the wrong time.\nPress R to unbind the key.")
		ElseIf option == delayOID
			SetInfoText("Time until the mesh is equipped after start of orgasm, and removed after the end of it. Can fix cumshots not showing up, or sticking after redressing. Increase the time if you have this problem, decrease it if you're feeling adventurous. 0.5s is the safe value from earlier versions.")
		ElseIf option == debugLvOID
			SetInfoText("Where debug messages are written to:\nNone at all, Papyrus log only, Log and console, Log and console and ingame messages.")
		ElseIf option == reloadJsonKeyOID
			SetInfoText("You can define a key to reload position adjustments from AdjustValues.json\nNormally you would never have to do this. However, this can come in handy if you're manually editing the file and want to test ingame.\nPress R to unbind the key.")
		ElseIf option == resetRngOID
			SetInfoText("Cumshot has a custom random number generator that is used in time critical situations (it avoids making external function calls which suspend script execution). Should it get stuck in a loop of always generating the same values, you can reset it here.")
		ElseIf option == orgasmDetectOID
			SetInfoText("How Cumshot detects if an actor has an orgasm:\nIndividually - supports separate orgasms, don't always occur at final stage\nHybrid mode - individual orgasm detection with orgasm assumed at final stage\nFinal stage - like in previous versions, doesn't detect separate orgasms")
		ElseIf option == victimsOID
			SetInfoText("If unchecked, victims will never ejaculate, even if 'Always show ejaculation' is active.\nIf checked, same ejaculation rules apply for victims as for everyone else.")
		ElseIf option == stageEventOID
			SetInfoText("In solo scenes, Flower Girls does not send the orgasm event at the right time. This option makes Cumshot use the Stage Advanced event as a workaround.")
		ElseIf option == arousalOID
			SetInfoText("High arousal increases ejaculation power (visible only in drop objects mode), and also cum amount (to a lesser extent).")
		ElseIf option == exposureOID
			SetInfoText("When set to anything other than zero, using the ejaculation hotkey will count as an orgasm and reduce arousal.\nThe value is the exposure reduced; arousal loss will be higher because the time of last orgasm is also reset.")
		EndIf

	ElseIf CurrentPage == "Visuals"
		If option == ejacModeOID
			String ejacModeInfo
			If ejaculationMode == 1
				ejacModeInfo = "Animated mesh - Same as in previous versions. Four spurts and an optional drip. Can be precisely positioned, but doesn't follow gravity."
			ElseIf ejaculationMode == 2
				ejacModeInfo = "Particles - A particle emitter that sends showers of drop particles. They react to gravity, but not to anything else."
			ElseIf ejaculationMode == 3
				ejacModeInfo = "Drop objects - A varying number of spurts that consist of cum drop objects. Ejaculations are highly customizable. Drops follow gravity and collide with world objects (but not with actors).\nWARNING - can cause high script usage."
			ElseIf ejaculationMode == 4
				ejacModeInfo = "Projectiles - A series of spells is fired from the penis, with cum spurts as projectiles. The spurts leave cum splashes on the ground and on objects."
			EndIf
			SetInfoText("The method, or technical implementation, to display the cumshot.\nDepending on the mode, some options may not be applicable / available.\n" + ejacModeInfo)
		ElseIf option == dripOID
			SetInfoText("Shows a cum drip hanging from the penis at the end of ejaculation. Only applies to Animated Mesh mode.")
		ElseIf option == tracerOID
			SetInfoText("In mesh and particle modes, some invisible objects are emitted as well. Mods can use trigger volumes to detect them.\nDrop objects and projectiles can be detected on their own, so they don't need this.")
		ElseIf option == amountOID
			SetInfoText("How big a load the actors will shoot.\nIf you have enabled the \"Draining and recovery\" option, the actual amount can vary a lot.")
		ElseIf option == powerOID
			SetInfoText("How fast cum is ejected, and how far it flies. Only applies to Drop Objects mode.")
		ElseIf option == ratioOID
			SetInfoText("Approximate number of spurts in the ejaculation.\nThis is just a rough guideline for an average cum amount. Due to randomization, the actual number of spurts can be different.")
		ElseIf option == alphaOID
			SetInfoText("At low values the spurts look transparent and watery, at high values they appear thick and white.")
		ElseIf option == unrealisticOID
			SetInfoText("Allows you to set the sliders to values that are pretty much over the top.\nWARNING: In drop objects mode, spawning a huge number of drops within a short time can cause spikes of high script usage, and maybe even stack dumps if Papyrus is already stressed by other mods.")
		ElseIf option == drainingOID
			SetInfoText("With this option enabled, guys won't have much cum left if they've just emptied their balls a short while ago. Cum amount recovers over time, up to 2.5 times the normal amount after not having had an orgasm for months.")
		ElseIf option == bodyOID
			SetInfoText("Select the body / schlong to adjust the cumshots for.")
		ElseIf option == indAmountOID
			If StorageUtil.HasFloatValue(crosshairRef, "CS2CumAmount")
				SetInfoText("Individual cum amount for this actor, overriding the global value.\nPress R to clear the override.")
			Else
				SetInfoText("Click to set cum amount individually for this actor, overriding the global value.")
			EndIf
		ElseIf option == indPowerOID
			If StorageUtil.HasFloatValue(crosshairRef, "CS2EjaculationPower")
				SetInfoText("Individual ejaculation power for this actor, overriding the global value.\nPress R to clear the override.")
			Else
				SetInfoText("Click to set ejaculation power individually for this actor, overriding the global value.")
			EndIf
		ElseIf option == indRatioOID
			If StorageUtil.HasFloatValue(crosshairRef, "CS2SpurtRatio")
				SetInfoText("Individual spurt ratio for this actor, overriding the global value.\nPress R to clear the override.")
			Else
				SetInfoText("Click to set the spurt ratio individually for this actor, overriding the global value.")
			EndIf
		ElseIf option == indAlphaOID
			If StorageUtil.HasFloatValue(crosshairRef, "CS2CumOpacity")
				SetInfoText("Individual cum opacity for this actor, overriding the global value.\nPress R to clear the override.")
			Else
				SetInfoText("Click to set cum opacity individually for this actor, overriding the global value.")
			EndIf
		EndIf

	ElseIf CurrentPage == "Genital data"
		If option == genActorOID
			SetInfoText("Click to toggle between the player's data and the data for the NPC under the crosshair (in case a valid NPC is targeted).")
		ElseIf option == genActiveOID
			If genType == 0
				If genIsFemale || !genMalesAlways
					SetInfoText("Enable the option if the actor's body has an integrated penis and is able to ejaculate.\nChecking this box creates a new database entry, unchecking it deletes an existing entry.")
				Else
					SetInfoText("Enable the option if the actor has a special body that requires different adjustments for the cumshot.\nChecking this box creates a new database entry, unchecking it deletes an existing entry.")
				EndIf
			Else
				If genIsFemale || !genMalesAlways
					SetInfoText("Enable the option if the actor's SOS addon / worn slot 52 item is a natural penis and allows them to ejaculate.\nChecking this box creates a new database entry, unchecking it deletes an existing entry.")
				Else
					SetInfoText("Enable the option if the actor's SOS addon / worn slot 52 item requires specific adjustments for the cumshot.\nChecking this box creates a new database entry. Unchecking it deletes an existing entry, along with all racial variants.")
				EndIf
			EndIf
		ElseIf option ==genKeyOID
			SetInfoText("You can rename the database entry. It will rename all racial and gender variants for this item as well. The name must be unique and must not contain the character '@'.")
		ElseIf option == genIsRacialOID && genType == 1
			SetInfoText("Enable the option if the penis has a special shape for this actor's race, which requires different adjustment values. It will create a separate database entry, valid only for that race.")
		ElseIf option == genappliesToOID && genType == 0
			SetInfoText("Choose if the settings for this actor's body apply to this character only (the ActorBase), or to the actor's race and gender.")
		ElseIf option == genMalesAlwaysOID
			SetInfoText("When this global setting is active, males are always able to ejaculate, regardless of whether they have a known SOS addon / equipable item / special body, or not. In the latter case they will use default adjustment values.")
		ElseIf option == genWeightDependentOID
			SetInfoText("Enable this if the active penis needs different cum adjustment values between body weights 0 and 100. If you disable it, the weight 0 values will apply to all body weights.")
		ElseIf option == genRotateOID
			SetInfoText("Adjusts the rotation of the cumshot. Increasing the value will make it shoot upward, decreasing the value will make it shoot downward.")
		ElseIf option == genMove0xOID || option == genMove100xOID
			SetInfoText("Adjusts the position of the cumshot relative to the outermost genitals node. Increasing the value moves it to the right, decreasing moves it to the left. Should be zero in all known cases.")
		ElseIf option == genMove0yOID || option == genMove100yOID
			SetInfoText("Adjusts the position of the cumshot relative to the outermost genitals node. Increasing the value moves it forward (away from the body), decreasing moves it back (toward the body).")
		ElseIf option == genMove0zOID || option == genMove100zOID
			SetInfoText("Adjusts the position of the cumshot relative to the outermost genitals node. Increasing the value moves it up, decreasing moves it down.")
		EndIf

	;/ElseIf CurrentPage == "Animations (SexLab)"
		If option == animPageOID
			SetInfoText("Change the page to see more animations.\nClick to select a page, or press R for next page.")
			Return
		ElseIf option == animPageDummyOID || option == slActionsOID
			Return
		EndIf
		Int i = animOID.Find(option)
		Int v = animValSL[i]
		Int p = animPosCountSL[i]
		String valInfo
		If v == -1
			valInfo = " - Undefined, default rules apply: If the animation is tagged as vaginal, oral, or anal, ejaculation is hidden for all actors but the first one. Otherwise, all ejaculations are shown."
		ElseIf v == 0
			valInfo = " - No ejaculations will be shown."
		ElseIf (v == 1 && p == 1)
			valInfo = " - Ejaculation will be displayed for the actor."
		ElseIf (v == 3 && p == 2)
			valInfo = " - Ejaculation will be displayed for both actors."
		ElseIf (v == 7 && p == 3) || (v == 15 && p == 4) || (v == 31 && p == 5)
			valInfo = " - Ejaculation will be displayed for all actors."
		ElseIf v == 1
			valInfo = " - Ejaculation will be displayed for the first actor."
		ElseIf v == 2
			valInfo = " - Ejaculation will be displayed for the second actor."
		ElseIf v == 4
			valInfo = " - Ejaculation will be displayed for the third actor."
		ElseIf v == 8
			valInfo = " - Ejaculation will be displayed for the fourth actor."
		ElseIf v == 16
			valInfo = " - Ejaculation will be displayed for the fifth actor."
		Else
			valInfo = " - Ejaculations will be displayed for the actors in these positions."
		EndIf
		SetInfoText(GetEjacCode(p, v) + valInfo)/;
	EndIf
EndEvent

;/Function ExplainSLAnimsTab()
	If ShowMessage("You can define which actors' ejaculations are visible in a specific animation, provided a male (or transgender female) actor is in that position. Click to cycle through the available settings.", True, "More...", "Exit")
		If ShowMessage("For example, [1 2 -] means that this animation has three actors, and ejaculations are displayed on the first and the second actor, but not on the third. In animations with two actors, the second position is usually the 'male' one.", True, "More...", "Exit")
			If ShowMessage("In the Actions menu you can rebuild the list of installed animations. This may become necessary if you have just installed SexLab at the same time as Cumshot, or updated SexLab.", True, "More...", "Exit")
				ShowMessage("If you choose to also reload rules, the defaults will be reapplied, and also your custom rules that you have saved with the last menu option. That way you can quickly apply your rules for different playthroughs.", False, "OK")
			EndIf
		EndIf
	EndIf
EndFunction/;


; Clamp all stats that are currently displayed and outside of normal range, and queue their entries for updating
Function ClampAndUpdateDisplayed()
	If cumAmount > 15.0
		cumAmount = 15.0
		SetSliderOptionValue(amountOID, cumAmount, "{2}", True)
	EndIf
	If ejaculationPower > 2.0
		ejaculationPower = 2.0
		SetSliderOptionValue(powerOID, ejaculationPower, "{2}", True)
	EndIf
	If spurtRatio > 10.0
		spurtRatio = 10.0
		SetSliderOptionValue(ratioOID, spurtRatio, "{2}", True)
	EndIf
	Float value
	value = StorageUtil.GetFloatValue(crosshairRef, "CS2CumAmount", -1.0)
	If value > 15.0
		StorageUtil.SetFloatValue(crosshairRef, "CS2CumAmount", 15.0)
		SetSliderOptionValue(indAmountOID, 15.0, "{2}", True)
	EndIf
	value = StorageUtil.GetFloatValue(crosshairRef, "CS2EjaculationPower", -1.0)
	If value > 2.0
		StorageUtil.SetFloatValue(crosshairRef, "CS2EjaculationPower", 2.0)
		SetSliderOptionValue(indPowerOID, 2.0, "{2}", True)
	EndIf
	value = StorageUtil.GetFloatValue(crosshairRef, "CS2SpurtRatio", -1.0)
	If value > 10.0
		StorageUtil.SetFloatValue(crosshairRef, "CS2SpurtRatio", 10.0)
		SetSliderOptionValue(indRatioOID, 10.0, "{2}", True)
	EndIf	
EndFunction


; Writes genital data prepared by Main.IdentifyGenitals() to the different MCM variables for display.
; This way we only have to do one external function call, which is much faster than writing to up to six external properties.
Function GenitalData(Int pType = 0, Form pForm = None, Bool pActive = False, String pKey = "", Bool pIsRacial = False, Bool pForFemale = False)
	genType = pType
	genForm = pForm
	genActive = pActive
	genKey = pKey
	genIsRacial = pIsRacial
	genForFemale = pForFemale

	; retrieving transform data
	If genActive || (genMalesAlways && !genIsFemale)
		If genKey == ""
			genKey = GetDefaultKey()
		EndIf
		genMove0 = new Float[3]
		genMove100 = new Float[3]
		genRotate = new Float[3]
		JsonUtil.FloatListSlice(jfile, genKey, genMove0, 0)  ; get three values at once from the adjustment data
		JsonUtil.FloatListSlice(jfile, genKey, genMove100, 3)
		JsonUtil.FloatListSlice(jfile, genKey, genRotate, 6)
	EndIf
EndFunction


; returns the default transformation key for the installed general body type
String Function GetDefaultKey()
	String defaultKey
	String aRace = genRace.GetName()
	If maleBodyClass == 0    ; esp-less body replacers
		defaultKey = maleBodyName
		If defaultKey == "SAM Light"
			If JsonUtil.StringListHas(jfile, "SAM Races", aRace)
				defaultKey = "SAM " + aRace
			EndIf
		Else
			If JsonUtil.StringListHas(jfile, "Static Races", aRace)
				defaultKey = aRace
			EndIf
		EndIf
	ElseIf maleBodyClass == 1  ; SOS Full
		defaultKey = "SOS Default"
	ElseIf maleBodyClass == 2  ; SOS Light
		defaultKey = maleBodyName
	ElseIf maleBodyClass == 3  ; SAM
		defaultKey = "SAM Default"
		If JsonUtil.StringListHas(jfile, "SAM Races", aRace)
			defaultKey = "SAM " + aRace
		EndIf
	EndIf
	Return defaultKey
EndFunction


; Build those neat codes like "[1 2 -]" in the SexLab animation menu that nobody understands
String Function GetEjacCode(Int positions, Int val)
	String ejacCode = ""
	If val == -1
		ejacCode = "? ? ? ? ? "  ; undefined
	Else
		Int i = 1
		While i <= positions
			If Math.LogicalAnd(val, Math.LeftShift(1, i - 1))
				ejacCode = ejacCode + i + " "
			Else
				ejacCode = ejacCode + "- "
			EndIf
			i += 1
		EndWhile
	EndIf
	Return "[ " + StringUtil.Substring(ejacCode, 0, positions * 2) + "]"
EndFunction
