extends "res://Scripts/Player/State.gd"

func _input(event):
	if (parent.playerControl != 0):
		if (event.is_action_pressed("gm_action")):
			if (parent.movement.x == 0 && parent.inputs[parent.INPUTS.YINPUT] > 0):
				parent.animator.play("spinDash")
				parent.sfx[2].play()
				parent.sfx[2].pitch_scale = 1;
				parent.spindashPower = 0;
				parent.animator.play("spindash")
				parent.set_state(parent.STATES.SPINDASH)
			else:
				parent.action_jump()
				parent.set_state(parent.STATES.JUMP)

func _process(delta):

	if parent.ground:
		if parent.movement.x == 0:
			if (parent.inputs[parent.INPUTS.YINPUT] > 0):
				if parent.lastActiveAnimation != "crouch":
					parent.animator.play("crouch")
			elif (parent.inputs[parent.INPUTS.YINPUT] < 0):
				if parent.lastActiveAnimation != "lookUp":
					parent.animator.play("lookUp")
			else:
				parent.animator.play("idle")
		elif(abs(parent.movement.x) < min(6*60,parent.top)):
			parent.animator.play("walk")
		elif(abs(parent.movement.x) < 10*60):
			parent.animator.play("run")
		else:
			parent.animator.play("peelOut")
	
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		parent.direction = parent.inputs[parent.INPUTS.XINPUT]

func _physics_process(delta):
	
	if (parent.inputs[parent.INPUTS.YINPUT] == 1 && abs(parent.movement.x) > 0.5*60):
		parent.set_state(parent.STATES.ROLL)
		parent.animator.play("roll")
		parent.sfx[1].play()
		return null;
	
	if (!parent.ground):
		parent.set_state(parent.STATES.AIR)
		#Stop script
		return null;
	parent.sprite.flip_h = (parent.direction < 0)
	
	parent.movement.y = min(parent.movement.y,0)
	
	# Apply slope factor
	# ignore this if not moving for sonic 1 style slopes
	parent.movement.x += (parent.slp*sin(parent.angle))/delta;
	
	var calcAngle = rad2deg(parent.angle)
	if (calcAngle < 0):
		calcAngle += 360;
	
	# drop, if speed below fall speed
	if (abs(parent.movement.x) < parent.fall && calcAngle >= 45 && calcAngle <= 315):
		if (round(calcAngle) >= 90 && round(calcAngle) <= 270):
			parent.disconect_from_floor()
		parent.lockTimer = 30.0/60.0;
		
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
			# check that decreasing movement won't go too far
			if (sign(parent.movement.x - (parent.frc/delta)*sign(parent.movement.x)) == sign(parent.movement.x)):
				parent.movement.x -= (parent.frc/delta)*sign(parent.movement.x)
			else:
				parent.movement.x -= parent.movement.x;
