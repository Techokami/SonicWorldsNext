extends "res://Scripts/Player/State.gd"

export var isJump = false;

func _physics_process(delta):
	
	# Air drag, don't know how accurate this is, may need some better tweaking
	if (parent.velocity.y < 0 && parent.velocity.y > -4*60):
		parent.velocity.x -= ((parent.velocity.x / int(0.125/delta)) / 256);
	
	if (isJump && !parent.inputs[parent.INPUTS.ACTION]):
		if (parent.velocity.y < -4*60):
			parent.velocity.y = -4*60;
	
	# gravity
	parent.velocity.y += parent.grv/delta;
	
	if (parent.ground):
		parent.set_state(parent.STATES.NORMAL);
	
	
	# air movement
	if (parent.inputs[parent.INPUTS.XINPUT] != 0 && parent.airControl):
		if (parent.velocity.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (abs(parent.velocity.x) < parent.top):
				parent.velocity.x = clamp(parent.velocity.x+parent.air/delta*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top);
