extends "res://Scripts/Player/State.gd"

func _process(delta):
	if parent.inputs[parent.INPUTS.ACTION] == 1:
		parent.action_jump()
		parent.set_state(parent.STATES.JUMP)
