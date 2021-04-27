extends "res://Scripts/Player/State.gd"

func _physics_process(delta):
	
	# Air drag, don't know how accurate this is, may need some better tweaking
	if (parent.velocity.y < 0 && parent.velocity.y > -4*60):
		parent.velocity.x -= ((parent.velocity.x * (0.125/delta)) / 256);
		
	parent.velocity.y += parent.grv/delta;
	if (parent.ground):
		parent.set_state(parent.STATES.NORMAL);
	
	
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		if (parent.velocity.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			parent.velocity.x += parent.acc/delta*parent.inputs[parent.INPUTS.XINPUT];
