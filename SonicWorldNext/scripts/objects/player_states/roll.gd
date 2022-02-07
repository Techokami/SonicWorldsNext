extends "res://scripts/objects/player_states/state.gd"


func _input(event):
	if (parent.playerControl != 0):
		if (event.is_action_pressed("gm_action")):
			# use parent.action_jump("Roll",false); to have jump lock similar to sonic 1-3
			# true replicates CD and Mania
			parent.action_jump("Roll",true);
			parent.set_state(parent.STATES.JUMP);


func _process(delta):
	var setSpeed = 60/floor(max(1,4-abs(parent.groundSpeed/60)));
	#parent.spriteFrames.set_animation_speed("roll",setSpeed);

func _physics_process(delta):
	
	
	if (!parent.ground):
		parent.set_state(parent.STATES.AIR,parent.HITBOXESSONIC.ROLL);
		return null;
	
	if (parent.movement.x == 0):
		parent.set_state(parent.STATES.NORMAL);
		return null;
	
	parent.movement.y = min(parent.movement.y,0);
	
	# Apply slope factor
	if (sign(parent.movement.x) != sign(sin(parent.angle))):
		parent.movement.x += (parent.slprollup*sin(parent.angle))/delta;
	else:
		parent.movement.x += (parent.slprolldown*sin(parent.angle))/delta;
	
	var calcAngle = rad2deg(parent.angle);
	if (calcAngle < 0):
		calcAngle += 360;
	
	# drop, if speed below fall speed
	if (abs(parent.movement.x) < parent.fall && calcAngle >= 45 && calcAngle <= 315):
		if (round(calcAngle) >= 90 && round(calcAngle) <= 270):
			parent.disconect_from_floor();
		parent.lockTimer = 30.0/60.0;
	
	
	
	
	if (parent.movement.x != 0):
		var checkX = sign(parent.movement.x);
		if (parent.inputs[parent.INPUTS.XINPUT] != 0 && sign(parent.movement.x) != parent.inputs[parent.INPUTS.XINPUT]):
			parent.movement.x += parent.rolldec/delta*parent.inputs[parent.INPUTS.XINPUT];
		
		parent.movement.x -= (parent.rollfrc/delta)*sign(parent.movement.x);

		if (sign(parent.movement.x) != checkX):
			parent.movement.x -= parent.movement.x;
	
	# clamp rolling top speed
	parent.movement.x = clamp(parent.movement.x,-parent.toproll,parent.toproll);
