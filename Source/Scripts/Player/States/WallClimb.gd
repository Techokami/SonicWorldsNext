extends "res://Scripts/Player/State.gd"

var climbPosition = Vector2.ZERO
var climbUp = false
var climbTimer = 0

var shiftPoses = [Vector2(4,-4),Vector2(13,-15),Vector2(4,-28),Vector2(13,-34)]

func state_activated():
	climbUp = false
	climbTimer = 0
	
func _physics_process(delta):
	# do climb logic if climbUp is false
	if !climbUp:
		
		# climbing
		parent.movement.y = (parent.inputs[parent.INPUTS.YINPUT]+int(parent.super)*sign(parent.inputs[parent.INPUTS.YINPUT]))*60
		
		# go to normal if on floor
		if parent.ground:
			parent.animator.play("walk")
			parent.groundSpeed = 1
			parent.disconect_from_floor()
			parent.set_state(parent.STATES.AIR,parent.currentHitbox.NORMAL)
			return false
		
		# check for wall using the wall sensors

		var velMem = parent.velocity
		parent.velocity = Vector2(parent.direction,-1)
		parent.update_sensors()
		parent.velocity = velMem
		
		# check to climb
		if !parent.horizontalSensor.is_colliding():
			parent.movement = Vector2.ZERO
			parent.animator.playback_speed = 1
			parent.set_state(parent.STATES.GLIDE,parent.currentHitbox.NORMAL)
			return false
		
		# climbing edge
		# move sensor to the top
		parent.horizontalSensor.position.y = -parent.get_node("HitBox").shape.extents.y
		parent.horizontalSensor.cast_to += parent.horizontalSensor.cast_to.normalized()*4
		parent.horizontalSensor.force_raycast_update()
		
		# check if the player can climb on top of the platform
		if !parent.horizontalSensor.is_colliding() and !parent.verticalSensorLeft.is_colliding() and !parent.verticalSensorRight.is_colliding():
			climbPosition = parent.global_position.ceil()+Vector2(0,5)
			parent.movement = Vector2.ZERO
			parent.animator.play("climbUp")
			climbUp = true
	else:
		parent.cameraDragLerp = 1
		climbTimer += delta
		parent.animator.stop()
		parent.animator.play("climbUp")
		var offset = (climbTimer/parent.animator.current_animation_length)*shiftPoses.size()
		parent.animator.advance(floor(offset)*0.1)
		parent.global_position = climbPosition+(shiftPoses[min(floor(offset),shiftPoses.size()-1)]*Vector2(parent.direction,1))
		if climbTimer > parent.animator.current_animation_length:
			parent.set_state(parent.STATES.NORMAL,parent.currentHitbox.NORMAL)
			climbUp = false
			parent.global_position = climbPosition+(shiftPoses[shiftPoses.size()-1]*Vector2(parent.direction,1))

func _process(delta):
	if parent.inputs[parent.INPUTS.ACTION] == 1 and !climbUp:
		parent.movement = Vector2(-4*60*parent.direction,-4*60)
		parent.direction *= -1
		parent.animator.play("roll")
		parent.animator.advance(0)
		parent.set_state(parent.STATES.JUMP)
