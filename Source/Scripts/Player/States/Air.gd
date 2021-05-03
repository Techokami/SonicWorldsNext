extends "res://Scripts/Player/State.gd"

export var isJump = false;

func _process(delta):
	if (parent.animator.current_animation == "Roll"):
		parent.animator.playback_speed = (1.0/4.0)+floor(min(4,abs(parent.groundSpeed/60)))/4;
	if (parent.animator.current_animation == "Walk" || parent.animator.current_animation == "Run"):
		parent.animator.playback_speed = (1.0/8.0)+floor(min(8,abs(parent.groundSpeed/60)))/8;

func _physics_process(delta):
	
	
	# air movement
	if (parent.inputs[parent.INPUTS.XINPUT] != 0 && parent.airControl):
		if (parent.velocity.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (abs(parent.velocity.x) < parent.top):
				parent.velocity.x = clamp(parent.velocity.x+parent.air/delta*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top);
				
	# Air drag, don't know how accurate this is, may need some better tweaking
	if (parent.velocity.y < 0 && parent.velocity.y > -4*60):
		#parent.velocity.x -= ((parent.velocity.x / int(0.125/delta)) / 256); old version
		parent.velocity.x -= ((parent.velocity.x / 0.125) / 256)*60*delta;
	
	if (isJump && !parent.inputs[parent.INPUTS.ACTION]):
		if (parent.velocity.y < -4*60):
			parent.velocity.y = -4*60;
	
	# gravity
	parent.velocity.y += parent.grv/delta;
	
	if (parent.ground):
		parent.set_state(parent.STATES.NORMAL);
	
	
