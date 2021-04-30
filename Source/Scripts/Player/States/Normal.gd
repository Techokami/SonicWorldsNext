extends "res://Scripts/Player/State.gd"



func _input(event):
	if (parent.playerControl != 0):
		if (event.is_action_pressed("gm_action")):
			if (parent.velocity.x == 0 && parent.inputs[parent.INPUTS.YINPUT] > 0):
				parent.animator.play("Spindash");
				parent.sfx[2].play();
				parent.sfx[2].pitch_scale = 1;
				parent.spindashPower = 0;
				parent.set_state(parent.STATES.SPINDASH);
			else:
				parent.action_jump();
				parent.set_state(parent.STATES.JUMP);

func _process(delta):
	if (parent.velocity.x == 0):
		if (parent.inputs[parent.INPUTS.YINPUT] > 0):
			parent.animator.play("Crouch");
		elif (parent.inputs[parent.INPUTS.YINPUT] < 0):
			parent.animator.play("LookUp");
		else:
			parent.animator.play("Idle");
	elif(abs(parent.velocity.x) < parent.top):
		parent.animator.play("Walk");
	else:
		parent.animator.play("Run");
	
	if (parent.velocity.x == 0):
		parent.animator.playback_speed = 1;
	else:
		#(floor(max(0, 8-abs(parent.velocity.x/(60*2))))/8);
		parent.animator.playback_speed = (1.0/8.0)+floor(min(8,abs(parent.groundSpeed/60)))/8;
	
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		parent.direction = parent.inputs[parent.INPUTS.XINPUT];

func _physics_process(delta):
	
	if (parent.inputs[parent.INPUTS.YINPUT] == 1 && abs(parent.velocity.x) > 0.5*60):
		parent.set_state(parent.STATES.ROLL);
		parent.animator.play("Roll");
		parent.sfx[1].play();
		return null;
		#parent.position += Vector2(0,5).rotated(parent.rotation);
	
	if (!parent.ground):
		parent.set_state(parent.STATES.AIR);
		#Stop script
		return null;
	parent.sprite.flip_h = (parent.direction < 0);
	
	parent.velocity.y = min(parent.velocity.y,0);
	
	# Apply slope factor
	# ignore this if not moving for sonic 1 style slopes
	parent.velocity.x -= (parent.slp*sin(-deg2rad(90)+parent.angle.angle()))/delta;
	
	var calcAngle = rad2deg(parent.angle.angle())+90;
	if (calcAngle < 0):
		calcAngle += 360;
	
	# drop, if speed below fall speed
	if (abs(parent.velocity.x) < parent.fall && calcAngle >= 45 && calcAngle <= 315):
		if (calcAngle >= 90 && calcAngle <= 270):
			parent.disconect_from_floor();
		parent.lockTimer = 30.0/60.0;
		
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
