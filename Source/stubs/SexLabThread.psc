ScriptName SexLabThread extends Quest
{Build-time stub for SexLab P+ 2.18.x - see SexLabFramework.psc stub.}

int Function GetThreadID()
EndFunction

String Function GetActiveScene()
EndFunction

String Function GetActiveStage()
EndFunction

Actor[] Function GetPositions()
EndFunction

int Function GetPositionIdx(Actor akActor)
EndFunction

bool Function GetSubmissive(Actor akActor)
EndFunction

; Names of the interaction types currently detected for akPosition,
; e.g. "aVaginal", "pOral", "pHandJob". See SexLabThread.psc in the P+ source.
string[] Function GetCurrentInteractionStringA(Actor akPosition)
EndFunction

string Function GetCurrentInteractionString(Actor akPosition)
EndFunction

; True when P+ has collision data (type-guessing) for this scene; false = placeholder / tag fallback.
bool Function IsInteractionRegistered()
EndFunction
