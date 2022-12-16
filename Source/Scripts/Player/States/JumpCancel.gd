extends "res://Scripts/Player/State.gd"

# this state with go to the jump state when jump is pressed

func _process(_delta):
	if parent.inputs[parent.INPUTS.ACTION] == 1 or parent.inputs[parent.INPUTS.ACTION2] == 1 or parent.inputs[parent.INPUTS.ACTION3] == 1:
		parent.action_jump()
		parent.set_state(parent.STATES.JUMP)
