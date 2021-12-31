extends "res://Scripts/Player/State.gd"


func _input(event):
	if (parent.playerControl != 0):
		if (event.is_action_pressed("gm_action")):
			# use parent.action_jump("Roll",false); to have jump lock similar to sonic 1-3
			# true replicates CD and Mania
			parent.action_jump("Roll",true);
			parent.set_state(parent.STATES.JUMP);


func _process(delta):
	var setSpeed = 60/floor(max(1,4-abs(parent.groundSpeed/60)));
	parent.spriteFrames.set_animation_speed("roll",setSpeed);

func _physics_process(delta):
	
	
	if (!parent.ground):
		parent.set_state(parent.STATES.AIR,parent.HITBOXESSONIC.ROLL);
		return null;
	
	if (parent.velocity.x == 0):
		parent.set_state(parent.STATES.NORMAL);
		return null;
	
	parent.velocity.y = min(parent.velocity.y,0);
	
	# Apply slope factor
	if (sign(parent.velocity.x) == sign(sin(-deg2rad(90)+parent.angle.angle()))):
		parent.velocity.x -= (parent.slprollup*sin(-deg2rad(90)+parent.angle.angle()))/delta;
	else:
		parent.velocity.x -= (parent.slprolldown*sin(-deg2rad(90)+parent.angle.angle()))/delta;
	
	var calcAngle = rad2deg(parent.angle.angle())+90;
	if (calcAngle < 0):
		calcAngle += 360;
	
	# drop, if speed below fall speed
	if (abs(parent.velocity.x) < parent.fall && calcAngle >= 45 && calcAngle <= 315):
		if (round(calcAngle) >= 90 && round(calcAngle) <= 270):
			parent.disconect_from_floor();
		parent.lockTimer = 30.0/60.0;
	
	
	
	
	if (parent.velocity.x != 0):
		var checkX = sign(parent.velocity.x);
		if (parent.inputs[parent.INPUTS.XINPUT] != 0 && sign(parent.velocity.x) != parent.inputs[parent.INPUTS.XINPUT]):
			parent.velocity.x += parent.rolldec/delta*parent.inputs[parent.INPUTS.XINPUT];
		
		parent.velocity.x -= (parent.rollfrc/delta)*sign(parent.velocity.x);

		if (sign(parent.velocity.x) != checkX):
			parent.velocity.x -= parent.velocity.x;
	
	# clamp rolling top speed
	parent.velocity.x = clamp(parent.velocity.x,-parent.toproll,parent.toproll);
	
