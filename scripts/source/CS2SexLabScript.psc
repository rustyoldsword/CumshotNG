ScriptName CS2SexLabScript Extends Quest
{Cumshot NG - SexLab P+ handler (standalone).

 Drop-in replacement for the "p+ Cumshot" build of this script. That build read the
 animation labels of one specific animation pack through a helper script that ships
 with it; without that pack installed every orgasm event died on a missing script and
 no cumshot was ever shown.

 This version asks SexLab P+ 2.18 itself what the actor is doing, through the public
 interaction (collision type-guessing) API on SexLabThread, which already falls back
 to the framework's own position tags when collision data is unavailable.}


CS2GameScript Property Main Auto
CS2ConfigScript Property Config Auto
SexLabFramework Property SexLab Auto

; --------------------------------------------------------------------
;                          Tunable rule set
; --------------------------------------------------------------------
; Read from Data/SKSE/Plugins/StorageUtilData/Cumshot/PPlusRules.json on every game load.
; "internal" = the penis is inside the partner, so no visible cumshot is drawn.

String ruleFile = "Cumshot/PPlusRules"
String logPath = "Data/SKSE/Plugins/Cumshot_PPlus.log"

Bool intVaginal = True
Bool intAnal = True
Bool intDeepthroat = True
Bool intSkullfuck = True
Bool intOral = True
Bool intGrinding = False
Bool requireContact = False
Bool hideWithoutData = True
Bool creatureStrict = True
Bool logEnabled = True
Float minOrgasmGap = 5.0

; where an orgasm call came from
Int SRC_ACTOR = 0
Int SRC_SCENE = 1


; --------------------------------------------------------------------
;                          Initialization
; --------------------------------------------------------------------

Event OnInit()
	Initialize()
	Main.DebugMessage("CS2 SexLab handler: Initialized (OnInit)")
EndEvent

; called on every game load
Function InitOnLoad()
	Initialize()
	Main.DebugMessage("CS2 SexLab handler: Initialized (InitOnLoad)")
EndFunction

Function Initialize()
	LoadRules()
	; Note: "SexLabOrgasmSeparate" is deliberately NOT registered. In old SexLab it came
	; from the separate "SexLab Separate Orgasm" mod; P+ sends it itself right after
	; "SexLabOrgasm", so registering both would fire two cumshots per orgasm.
	RegisterForModEvent("SexLabOrgasm", "OrgasmSL")
	RegisterForModEvent("HookOrgasmStart", "OrgasmSLAll")
	RegisterForModEvent("HookOrgasmEnd", "OrgasmEndSL")
	RegisterForModEvent("HookAnimationEnding", "CleanUpSL")
	CSLog("Handler initialised. Rules: V=" + intVaginal + " A=" + intAnal + " DT=" + intDeepthroat + " SF=" + intSkullfuck + " O=" + intOral + " G=" + intGrinding + " requireContact=" + requireContact + " hideWithoutData=" + hideWithoutData + " creatureStrict=" + creatureStrict + " gap=" + minOrgasmGap)
EndFunction

Function LoadRules()
	If !JsonUtil.JsonExists(ruleFile)
		Return  ; keep the compiled-in defaults
	EndIf
	JsonUtil.Load(ruleFile)
	intVaginal = JsonUtil.GetPathIntValue(ruleFile, ".internal.vaginal", 1) != 0
	intAnal = JsonUtil.GetPathIntValue(ruleFile, ".internal.anal", 1) != 0
	intDeepthroat = JsonUtil.GetPathIntValue(ruleFile, ".internal.deepthroat", 1) != 0
	intSkullfuck = JsonUtil.GetPathIntValue(ruleFile, ".internal.skullfuck", 1) != 0
	intOral = JsonUtil.GetPathIntValue(ruleFile, ".internal.oral", 1) != 0
	intGrinding = JsonUtil.GetPathIntValue(ruleFile, ".internal.grinding", 0) != 0
	requireContact = JsonUtil.GetPathIntValue(ruleFile, ".requireContact", 0) != 0
	hideWithoutData = JsonUtil.GetPathIntValue(ruleFile, ".hideWithoutData", 1) != 0
	creatureStrict = JsonUtil.GetPathIntValue(ruleFile, ".creatureStrict", 1) != 0
	logEnabled = JsonUtil.GetPathIntValue(ruleFile, ".log", 1) != 0
	minOrgasmGap = JsonUtil.GetPathFloatValue(ruleFile, ".minOrgasmGap", 5.0)
EndFunction


; --------------------------------------------------------------------
;                       SexLab event handlers
; --------------------------------------------------------------------

; One orgasm of one actor. P+ sends this for every actor, every time.
Event OrgasmSL(Form actorForm, Int enjoyment, Int orgasmCount)
	HandleOrgasm(actorForm as Actor, SRC_ACTOR)
EndEvent

; Scene reached an orgasm stage. Only used by the legacy detection modes.
Event OrgasmSLAll(Int tid, Bool hasPlayer)
	If Config.orgasmDetectMode == 0
		Return  ; orgasms are tracked individually, nothing to do here
	EndIf
	SexLabThread slScene = SexLab.GetThread(tid)
	If !slScene
		Return
	EndIf
	Actor[] actorList = slScene.GetPositions()
	Int actorCount = actorList.Length
	CSLog("Scene orgasm stage: " + SceneLabel(slScene) + " (" + actorCount + " actors)")
	Int i = 0
	While i < actorCount
		HandleOrgasm(actorList[i], SRC_SCENE)
		i += 1
	EndWhile
EndEvent

; The orgasm stage ended - take the cumshot off again, but leave the item in the
; inventory so a second ejaculation in the same scene does not make NPCs redress.
Event OrgasmEndSL(Int tid, Bool hasPlayer)
	CleanUpScene(tid, False)
EndEvent

; The whole scene is ending - remove everything for good.
Event CleanUpSL(Int tid, Bool hasPlayer)
	CleanUpScene(tid, True)
EndEvent


; --------------------------------------------------------------------
;                          Orgasm handling
; --------------------------------------------------------------------

Function HandleOrgasm(Actor orgasmee, Int source)
	If !orgasmee
		Return
	EndIf
	Int mode = Config.orgasmDetectMode  ; 0 individually, 1 hybrid, 2 final stage
	If source == SRC_SCENE && mode == 0
		Return
	ElseIf source == SRC_ACTOR && mode == 2
		Return  ; final-stage mode ignores the individual orgasm events
	EndIf

	SexLabThread slScene = SexLab.GetThreadByActor(orgasmee)
	If !slScene
		CSLog(ActorLabel(orgasmee) + ": no SexLab thread, ignored")
		Return
	EndIf

	; Hybrid mode: the scene-wide pass only covers actors that have not cum yet.
	If source == SRC_SCENE && mode == 1
		If StorageUtil.GetIntValue(orgasmee, "CS2_EjacThread", -1) == slScene.GetThreadID()
			Return
		EndIf
	EndIf

	; Both events can fire for the same orgasm - only let one of them through.
	Float now = Utility.GetCurrentRealTime()
	If now - StorageUtil.GetFloatValue(orgasmee, "CS2_LastEjacReal", -9999.0) < minOrgasmGap
		Return
	EndIf

	If !Config.victimsEjaculate && slScene.GetSubmissive(orgasmee)
		CSLog(ActorLabel(orgasmee) + ": victim, ejaculation suppressed")
		Return
	EndIf

	If !Config.alwaysShowEjac && !ShowEjac(slScene, orgasmee)
		StorageUtil.SetFloatValue(orgasmee, "CS2_LastOrgasmTime", Utility.GetCurrentGameTime())
		Return
	EndIf

	StorageUtil.SetFloatValue(orgasmee, "CS2_LastEjacReal", now)
	StorageUtil.SetIntValue(orgasmee, "CS2_EjacThread", slScene.GetThreadID())

	Form cumObject = StorageUtil.PluckFormValue(orgasmee, "CS2_ejaculating")
	If cumObject
		; don't fully remove, it would make NPCs redress on a second ejaculation in a scene
		orgasmee.UnequipItem(cumObject, abPreventEquip = True, abSilent = True)
	EndIf
	Float tDecided = Utility.GetCurrentRealTime()
	Main.Ejaculate(orgasmee)
	Float tDone = Utility.GetCurrentRealTime()
	; GetCurrentRealTime() only advances once per frame, so a big "decision" number means
	; the game hitched inside this handler, not that the handler did much work.
	; Ejaculate() is blocking and includes the MCM equip delay plus the seconds the mesh
	; is worn, so its number is expected to be several seconds - it is not a stall.
	CSLog(ActorLabel(orgasmee) + ": decision " + Math.Floor((tDecided - now) * 1000.0) + " ms, Ejaculate() " + Math.Floor((tDone - tDecided) * 1000.0) + " ms")
	StorageUtil.SetFloatValue(orgasmee, "CS2_LastOrgasmTime", Utility.GetCurrentGameTime())
EndFunction


; Decide whether a visible (external) cumshot fits what the actor is doing right now.
; The ejaculation is shown when the actor's penis is OUTSIDE a partner: handjob, footjob,
; boobjob, shaft licking, facial, grinding, nothing engaged - and also when the actor is the
; one being penetrated (a futa / male bottom cums with a free penis). It is hidden when the
; penis is inside a vagina, an anus or a mouth, and when the scene gives no reliable data.
Bool Function ShowEjac(SexLabThread slScene, Actor orgasmee)
	; The comma-separated names are used, not the Bool[] flags or the String[] variant:
	; names are stable across P+ versions (the flag indices are not), and a plain string
	; cannot come back as a None array when nothing is detected.
	; "a<X>" = this actor's own body does X to a partner, "p<X>" = a partner does X to
	; this actor (pOral = this actor's crotch is licked / sucked, pDeepthroat = this actor's
	; penis is deep in a mouth, aDeepthroat = this actor's own mouth is the one deep-throating).
	String flags = slScene.GetCurrentInteractionString(orgasmee)
	Bool registered = slScene.IsInteractionRegistered()
	String head = ActorLabel(orgasmee) + " @ " + SceneLabel(slScene) + " [" + flags + "] reg=" + registered + " -> "

	If hideWithoutData
		; Without collision data P+ substitutes a placeholder (pAnal for everyone), so what it
		; reports is not what happens on screen. Creature scenes typically end up here.
		If !registered
			CSLog(head + "hidden: no collision data")
			Return False
		ElseIf IsPlaceholderData(slScene)
			CSLog(head + "hidden: placeholder data (every position reports pAnal)")
			Return False
		EndIf
	EndIf

	; Creature scenes: only draw it when the flags positively name an outside interaction.
	; Whatever else P+ reports there (a lone pAnal, nothing at all) cannot be trusted.
	If creatureStrict && IsCreatureScene(slScene)
		If !(HasFlag(flags, "pHandJob") || HasFlag(flags, "pFootJob") || HasFlag(flags, "pBoobJob") || HasFlag(flags, "pLickingShaft") || HasFlag(flags, "aFacial"))
			CSLog(head + "hidden: creature scene without a clear outside interaction")
			Return False
		EndIf
	EndIf

	If flags == ""
		CSLog(head + CumshotVerdict(True) + " (nothing engaged)")
		Return True
	EndIf

	Bool inside = (intVaginal && HasFlag(flags, "aVaginal")) || (intAnal && HasFlag(flags, "aAnal")) || (intDeepthroat && HasFlag(flags, "pDeepthroat")) || (intSkullfuck && HasFlag(flags, "aSkullfuck")) || (intOral && HasFlag(flags, "pOral")) || (intGrinding && HasFlag(flags, "aGrinding"))

	Bool result = !inside
	If result && requireContact
		; only spray when the penis is actually involved in something
		result = HasFlag(flags, "pOral") || HasFlag(flags, "aGrinding") || HasFlag(flags, "pHandJob") || HasFlag(flags, "pFootJob") || HasFlag(flags, "pBoobJob") || HasFlag(flags, "pLickingShaft") || HasFlag(flags, "aFacial") || HasFlag(flags, "aVaginal") || HasFlag(flags, "aAnal") || HasFlag(flags, "pDeepthroat") || HasFlag(flags, "aSkullfuck")
	EndIf

	CSLog(head + CumshotVerdict(result))
	Return result
EndFunction


; Any position is a creature (SexLab sex 3 / 4 = CrtMale / CrtFemale, the same test P+ uses).
Bool Function IsCreatureScene(SexLabThread slScene)
	Actor[] pos = slScene.GetPositions()
	Int i = 0
	While i < pos.Length
		If SexLabRegistry.GetSex(pos[i], True) >= 3
			Return True
		EndIf
		i += 1
	EndWhile
	Return False
EndFunction

Bool Function HasFlag(String csv, String name)
	Return StringUtil.Find("," + csv + ",", "," + name + ",") >= 0
EndFunction

; True when every position of the scene reports exactly "pAnal" - physically impossible with
; real collision data (somebody has to be the one penetrating), it is P+'s placeholder.
Bool Function IsPlaceholderData(SexLabThread slScene)
	Actor[] pos = slScene.GetPositions()
	If pos.Length < 2
		Return False
	EndIf
	Int i = 0
	While i < pos.Length
		If slScene.GetCurrentInteractionString(pos[i]) != "pAnal"
			Return False
		EndIf
		i += 1
	EndWhile
	Return True
EndFunction


Function CleanUpScene(Int tid, Bool finalCleanup)
	SexLabThread slScene = SexLab.GetThread(tid)
	If !slScene
		Return
	EndIf
	Actor[] actorList = slScene.GetPositions()
	Int actorCount = actorList.Length
	Float delay = Config.equipDelay  ; in case cum was added right at the end of the stage
	Int i = 0
	While i < actorCount
		Main.RemoveCumshot(actorList[i], waitTime = delay, forceRemove = finalCleanup)
		If finalCleanup
			StorageUtil.UnsetIntValue(actorList[i], "CS2_EjacThread")
		EndIf
		i += 1
	EndWhile
EndFunction


; --------------------------------------------------------------------
;                          Small helpers
; --------------------------------------------------------------------

String Function ActorLabel(Actor a)
	Return a.GetLeveledActorBase().GetName()
EndFunction

String Function SceneLabel(SexLabThread slScene)
	Return SexLabRegistry.GetSceneName(slScene.GetActiveScene()) + "/" + slScene.GetActiveStage()
EndFunction

String Function CumshotVerdict(Bool show)
	If show
		Return "cumshot"
	EndIf
	Return "internal, no cumshot"
EndFunction

Function CSLog(String msg)
	If !logEnabled
		Return
	EndIf
	; real time is logged so lines can be lined up with Papyrus.0.log, whose timestamps
	; only have one-second resolution
	MiscUtil.WriteToFile(logPath, "[Cumshot P+] [" + Math.Floor(Utility.GetCurrentRealTime()) + "s] " + msg + "\n", True, True)
	If Config.debugMsgLevel > 1
		MiscUtil.PrintConsole("[Cumshot P+] " + msg)
	EndIf
EndFunction
