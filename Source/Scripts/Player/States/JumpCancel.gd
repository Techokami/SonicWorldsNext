extends "res://Scripts/Player/State.gd"

func _input(event):
	if (parent.playerControl != 0):
		if (event.is_action_pressed("gm_action")):
				parent.action_jump()
				parent.set_state(parent.STATES.JUMP)
