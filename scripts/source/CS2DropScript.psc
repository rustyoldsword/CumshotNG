ScriptName CS2DropScript Extends ObjectReference

ObjectReference a
Float vx
Float vy
Float vz
Float speed
Float scale
ObjectReference proxy
Int stage

; Only copy parameters to script variables for now,
; so the function finishes quickly, and the calling script can continue.
Function Launch(ObjectReference pA, Float pVx, Float pVy, Float pVz, Float pSpeed, Float pScale, ObjectReference pProxy)
	a = pA
	vx = pVx
	vy = pVy
	vz = pVz
	speed = pSpeed
	scale = pScale
	proxy = pProxy
	stage = 1
	RegisterForSingleUpdate(0.01)
EndFunction

Event OnUpdate()
	If stage == 1  ; first invocation from the Launch function
		If scale < 0.5
			scale = 0.5
		ElseIf scale > 1.5
			scale = 1.5
		EndIf
		SetScale(scale)
		If proxy
			MoveTo(proxy)
		Else
			MoveToNode(a, "Urethra")
		EndIf
		stage = 2
		RegisterForSingleUpdate(2.0)  ; give it 2 seconds for the OnLoad() event to trigger
	ElseIf stage == 2  ; The drop's 3D still hasn't loaded after two seconds
		stage = 9
		Debug.Trace("CS2: Drop " + Self + " hasn't loaded after two seconds - deleting it.")
		Delete()
	ElseIf stage == 4  ; Lifetime of a properly loaded and fired drop has ended
		stage = 9
		Disable()
		; NOTE: I would have liked to make the drops fade out, but there are insurmountable problems.
		; Any reference created or enabled while another reference of the same type is fading out, will not become visible,
		; even though Is3DLoaded() returns true, and script functions that manipulate the object process without errors.
		Delete()
	EndIf
EndEvent

Event OnLoad()
	If stage == 1 || stage == 2
		stage = 3  ; this will keep an OnUpdate() from deleting the drop in case it occurs exactly at this time
		ApplyHavokImpulse(vx, vy, vz, speed)
		RegisterForSingleUpdate(1.5)  ; resets and overrides the previous RegisterForSingleUpdate(2.0) from stage 2
		stage = 4
	EndIf
	; otherwise do nothing - the drop hasn't loaded at the appropriate stage
EndEvent

; Failsafe, in case the drop isn't gone yet when the player leaves the cell
Event OnCellDetach()
	UnregisterForUpdate()
	Delete()
EndEvent
