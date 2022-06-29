extends "res://Scripts/Player/State.gd"



func _process(delta):
	if parent.inputs[parent.INPUTS.ACTION] == 1:
		# use parent.action_jump("roll",false) to have jump lock similar to sonic 1-3
		# true replicates CD and Mania
		parent.action_jump("roll",true)
		parent.set_state(parent.STATES.JUMP)

func _physics_process(delta):
	
	# Set air if not on floor
	if (!parent.ground):
		parent.set_state(parent.STATES.AIR,parent.currentHitbox.ROLL)
		return null
	# Set normal if speed is 0
	if (parent.movement.x == 0):
		parent.set_state(parent.STATES.NORMAL)
		return null
	
	# Lock vertical movement
	parent.movement.y = min(parent.movement.y,0)
	
	# Apply slope factor
	if (sign(parent.movement.x) != sign(sin(parent.angle))):
		parent.movement.x += (parent.slprollup*sin(parent.angle))/delta
	else:
		parent.movement.x += (parent.slprolldown*sin(parent.angle))/delta
	
	var calcAngle = rad2deg(parent.angle)
	if (calcAngle < 0):
		calcAngle += 360
	
	# drop, if speed below fall speed
	if (abs(parent.movement.x) < parent.fall && calcAngle >= 45 && calcAngle <= 315):
		if (round(calcAngle) >= 90 && round(calcAngle) <= 270):
			parent.disconect_from_floor()
		
		parent.horizontalLockTimer = 30.0/60.0
	
	
	
	
	if (parent.movement.x != 0):
		var checkX = sign(parent.movement.x)
		if (parent.inputs[parent.INPUTS.XINPUT] != 0 && sign(parent.movement.x) != parent.inputs[parent.INPUTS.XINPUT]):
			parent.movement.x += parent.rolldec/delta*parent.inputs[parent.INPUTS.XINPUT]
		
		parent.movement.x -= (parent.rollfrc/delta)*sign(parent.movement.x)

		if (sign(parent.movement.x) != checkX):
			parent.movement.x -= parent.movement.x
	
	# clamp rolling top speed
	parent.movement.x = clamp(parent.movement.x,-parent.toproll,parent.toproll)
