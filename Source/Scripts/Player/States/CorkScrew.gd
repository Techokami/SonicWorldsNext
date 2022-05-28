extends "res://Scripts/Player/State.gd"

func _process(delta):
	if parent.inputs[parent.INPUTS.ACTION] == 1:
		parent.action_jump()
		parent.set_state(parent.STATES.JUMP)

func _physics_process(delta):
	# gravity
	parent.movement.y += parent.grv/delta
	
	parent.sprite.flip_h = (parent.direction < 0)
		
	#var calcAngle = rad2deg(parent.angle.angle())+90
	var calcAngle = wrapf(rad2deg(parent.angle),0,360)
	if (calcAngle < 0):
		calcAngle += 360
	
		
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		if (parent.movement.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (sign(parent.movement.x) == parent.inputs[parent.INPUTS.XINPUT]):
				if (abs(parent.movement.x) < parent.top):
					parent.movement.x = clamp(parent.movement.x+parent.acc/delta*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top)
			else:
				# reverse direction
				parent.movement.x += parent.dec/delta*parent.inputs[parent.INPUTS.XINPUT]
				# implament weird turning quirk
				if (sign(parent.movement.x) != sign(parent.movement.x-parent.dec/delta*parent.inputs[parent.INPUTS.XINPUT])):
					parent.movement.x = 0.5*60*sign(parent.movement.x)
	else:
		if (parent.movement.x != 0):
			# needs better code
			if (sign(parent.movement.x - (parent.frc/delta)*sign(parent.movement.x)) == sign(parent.movement.x)):
				parent.movement.x -= (parent.frc/delta)*sign(parent.movement.x)
			else:
				parent.movement.x -= parent.movement.x
	
	# reset state
	if parent.ground:
		if parent.animator.current_animation == "roll":
			parent.set_state(parent.STATES.ROLL)
		else:
			parent.set_state(parent.STATES.NORMAL)
