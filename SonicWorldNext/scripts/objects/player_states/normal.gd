extends "res://scripts/objects/player_states/state.gd"

func _input(event):
	if (parent.playerControl != 0):
		if (event.is_action_pressed("gm_action")):
			if (parent.movement.x == 0 && parent.inputs[parent.INPUTS.YINPUT] > 0):
				parent.sprite.play("spinDash");
#				parent.sfx[2].play();
#				parent.sfx[2].pitch_scale = 1;
				parent.spindashPower = 0;
				parent.sprite.play("spindash");
				parent.set_state(parent.STATES.SPINDASH);
			else:
				parent.action_jump();
				parent.set_state(parent.STATES.JUMP);

func _process(delta):
#	if (parent.movement.x != 0):
#		#var setSpeed = (1.0/8.0)+floor(min(8,abs(parent.groundSpeed/60)))/8;
#		var setSpeed = 60/floor(max(1,8-abs(parent.groundSpeed/60)));
#		parent.spriteFrames.set_animation_speed("walk",setSpeed);
#		parent.spriteFrames.set_animation_speed("run",setSpeed);
#		parent.spriteFrames.set_animation_speed("peelOut",setSpeed);

	if parent.ground:
		if parent.movement.x == 0:
			if (parent.inputs[parent.INPUTS.YINPUT] > 0):
				parent.sprite.play("crouch");
			elif (parent.inputs[parent.INPUTS.YINPUT] < 0):
				parent.sprite.play("lookUp");
			else:
				parent.sprite.play("idle");
		elif(abs(parent.movement.x) < parent.top):
			parent.sprite.play("walk");
		elif(abs(parent.movement.x) < 10*60):
			parent.sprite.play("run");
		else:
			parent.sprite.play("peelOut");
	
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		parent.direction = parent.inputs[parent.INPUTS.XINPUT];

func _physics_process(delta):
	
	if (parent.inputs[parent.INPUTS.YINPUT] == 1 && abs(parent.movement.x) > 0.5*60):
		parent.set_state(parent.STATES.ROLL);
		parent.sprite.play("roll");
		#parent.sfx[1].play();
		return null;
		#parent.position += Vector2(0,5).rotated(parent.rotation);
	
	if (!parent.ground):
		parent.set_state(parent.STATES.AIR);
		#Stop script
		return null;
	parent.sprite.flip_h = (parent.direction < 0);
	
	parent.movement.y = min(parent.movement.y,0);
	
	# Apply slope factor
	# ignore this if not moving for sonic 1 style slopes
	parent.movement.x += (parent.slp*sin(parent.angle))/delta;
	#parent.movement.x = 100*parent.inputs[parent.INPUTS.XINPUT]
	
	var calcAngle = rad2deg(parent.angle);
	if (calcAngle < 0):
		calcAngle += 360;
	
	# drop, if speed below fall speed
	if (abs(parent.movement.x) < parent.fall && calcAngle >= 45 && calcAngle <= 315):
		if (round(calcAngle) >= 90 && round(calcAngle) <= 270):
			parent.disconect_from_floor();
		parent.lockTimer = 30.0/60.0;
		
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		if (parent.movement.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (sign(parent.movement.x) == parent.inputs[parent.INPUTS.XINPUT]):
				if (abs(parent.movement.x) < parent.top):
					parent.movement.x = clamp(parent.movement.x+parent.acc/delta*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top);
			else:
				# reverse direction
				parent.movement.x += parent.dec/delta*parent.inputs[parent.INPUTS.XINPUT];
				# implament weird turning quirk
				if (sign(parent.movement.x) != sign(parent.movement.x-parent.dec/delta*parent.inputs[parent.INPUTS.XINPUT])):
					parent.movement.x = 0.5*60*sign(parent.movement.x);
	else:
		if (parent.movement.x != 0):
			# needs better code
			if (sign(parent.movement.x - (parent.frc/delta)*sign(parent.movement.x)) == sign(parent.movement.x)):
				parent.movement.x -= (parent.frc/delta)*sign(parent.movement.x);
			else:
				parent.movement.x -= parent.movement.x;
