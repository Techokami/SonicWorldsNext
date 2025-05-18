extends PlayerState

var climbPosition = Vector2.ZERO
var climbUp = false
var climbTimer = 0

var shiftPoses = [Vector2(4,-4),Vector2(13,-15),Vector2(4,-28),Vector2(13,-34)]

# TODO fix bugs
#  1 - Back over in Glide.gd, we need to make the character teleport upwards and slide if they hit
#      the wall while being high enough to climb up on the next frame
#  2 - Currently if the player is pushed out by something unclimbable, they stick in the air.

func state_activated():
	climbUp = false
	climbTimer = 0


func state_process(_delta: float) -> void:
	# jumping off
	if (parent.inputs[parent.INPUTS.ACTION] == 1 or parent.inputs[parent.INPUTS.ACTION2] == 1 or parent.inputs[parent.INPUTS.ACTION3] == 1) and !climbUp:
		var animator: PlayerCharAnimationPlayer = parent.get_avatar().get_animator()
		parent.movement = Vector2(-4*60*parent.direction,-4*60)
		parent.direction *= -1
		animator.play("roll")
		animator.advance(0)
		parent.set_state(parent.STATES.JUMP)


func state_physics_process(delta: float) -> void:
	# do climb logic if climbUp is false
	var animator: PlayerCharAnimationPlayer = parent.get_avatar().get_animator()
	if !climbUp:
		
		# climbing
		parent.movement.y = (parent.inputs[parent.INPUTS.YINPUT]+int(parent.isSuper)*sign(parent.inputs[parent.INPUTS.YINPUT]))*60
		#Prevent player from leaving play area via climbing.
		parent.global_position.y = clampf(parent.global_position.y,parent.limitTop+16,parent.limitBottom)
		
		# check vertically (sometimes clinging can cause clipping)
		if parent.movement.y == 0:
			parent.movement.y = -1
			parent.update_sensors()
			parent.verticalSensorLeft.force_raycast_update()
			parent.verticalSensorRight.force_raycast_update()
			if !parent.verticalSensorLeft.is_colliding() and !parent.verticalSensorRight.is_colliding():
				parent.movement.y = 0
		
			
		# go to normal if on floor
		if parent.ground:
			animator.play("walk")
			parent.groundSpeed = 1
			parent.disconnect_from_floor()
			parent.set_state(parent.STATES.AIR,parent.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL))
			return
		
		# check for wall using the wall sensors

		var velMem = parent.velocity
		parent.velocity = Vector2(parent.direction,-1)
		parent.update_sensors()
		parent.velocity = velMem
		
		# check to climb
		if !parent.horizontalSensor.is_colliding():
			parent.movement = Vector2.ZERO
			animator.speed_scale = 1
			parent.set_character_action_state(KnucklesAvatar.CHAR_STATES.KNUCKLES_CLIMB,
			                    parent.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL))
			return
		
		# climbing edge
		# move sensor to the top
		parent.horizontalSensor.position.y = -parent.get_node("HitBox").shape.size.y/2
		parent.horizontalSensor.target_position += parent.horizontalSensor.target_position.normalized()*4
		parent.horizontalSensor.force_raycast_update()
		
		# check if the player can climb on top of the platform
		if !parent.horizontalSensor.is_colliding() and !parent.verticalSensorLeft.is_colliding() and !parent.verticalSensorRight.is_colliding():
			climbPosition = parent.global_position.ceil()+Vector2(0,5)
			parent.movement = Vector2.ZERO
			animator.play("climbUp")
			climbUp = true
	else:
		# climb up
		# give camera time to follow so it doesn't snap
		parent.cameraDragLerp = 1
		climbTimer += delta
		# stop current animations and play climb up
		animator.stop()
		animator.play("climbUp")
		# use offset based on the current animations and how many poses there are in shiftPoses (shiftPoses should match how many frames you're using)
		var offset = (climbTimer/animator.current_animation_length)*shiftPoses.size()
		
		animator.advance(floor(offset)*0.1)
		parent.global_position = climbPosition+(shiftPoses[min(floor(offset),shiftPoses.size()-1)]*Vector2(parent.direction,1))
		# if timer greater then animator then exit climb
		if climbTimer > animator.current_animation_length:
			parent.set_state(parent.STATES.NORMAL,parent.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL))
			climbUp = false
			parent.global_position = climbPosition+(shiftPoses[shiftPoses.size()-1]*Vector2(parent.direction,1))
