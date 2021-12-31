extends "res://Scripts/Player/State.gd"

func _physics_process(delta):
	# gravity
	parent.velocity.y += parent.grv/delta;
	
	parent.sprite.flip_h = (parent.direction < 0);
		
	var calcAngle = rad2deg(parent.angle.angle())+90;
	if (calcAngle < 0):
		calcAngle += 360;
	
		
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		if (parent.velocity.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (sign(parent.velocity.x) == parent.inputs[parent.INPUTS.XINPUT]):
				if (abs(parent.velocity.x) < parent.top):
					parent.velocity.x = clamp(parent.velocity.x+parent.acc/delta*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top);
			else:
				# reverse direction
				parent.velocity.x += parent.dec/delta*parent.inputs[parent.INPUTS.XINPUT];
				# implament weird turning quirk
				if (sign(parent.velocity.x) != sign(parent.velocity.x-parent.dec/delta*parent.inputs[parent.INPUTS.XINPUT])):
					parent.velocity.x = 0.5*60*sign(parent.velocity.x);
	else:
		if (parent.velocity.x != 0):
			# needs better code
			if (sign(parent.velocity.x - (parent.frc/delta)*sign(parent.velocity.x)) == sign(parent.velocity.x)):
				parent.velocity.x -= (parent.frc/delta)*sign(parent.velocity.x);
			else:
				parent.velocity.x -= parent.velocity.x;
	
	if parent.ground:
		parent.set_state(parent.STATES.NORMAL);
