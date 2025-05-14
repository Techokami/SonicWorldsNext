extends PlayerState

# first is normal, second is super speed
var glideAccel = [0.015625,0.046875]
var glideGrav = 0.125
var friction = 0.125
var speedClamp = 24*60

var turnTimer = 0
var speedPreservation = 0

var isFall = false
var landed = false
var sliding = false

# add a ground buffer so that the player won't have just 1 frame on the ground send them into a slide (for example monitors)
var groundBuffer = 0

func state_activated():
	groundBuffer = 0
	# if no movement on the x axis then go into a fall immediately
	if parent.movement.x == 0:
		isFall = true
		landed = false
		sliding = false
		parent.animator.play("glideFall")
		parent.animator.advance(1)
		
	else:
		if parent.movement.x > 0:
			turnTimer = 0
		else:
			turnTimer = 180
		speedPreservation = abs(parent.movement.x)
		parent.animator.play("glide")
		# work around for animation (needed for attacking flag)
		parent.lastActiveAnimation = "glide"
		isFall = false
		landed = false
		sliding = false
		parent.reflective = true

func state_exit():
	parent.reflective = false


func state_process(_delta: float) -> void:
	# Jump and Spindash cancel
	if (parent.inputs[parent.INPUTS.ACTION] == 1 or parent.inputs[parent.INPUTS.ACTION2] == 1 or parent.inputs[parent.INPUTS.ACTION3] == 1) and parent.ground and (sliding or isFall):
		parent.movement.x = 0
		if (parent.inputs[parent.INPUTS.YINPUT] > 0):
			parent.animator.play("spinDash")
			parent.sfx[2].play()
			parent.sfx[2].pitch_scale = 1
			parent.spindashPower = 0
			parent.animator.play("spinDash")
			parent.set_state(parent.STATES.SPINDASH)
			parent.cameraDragLerp = 1
		else:
			# reset animations
			parent.action_jump()
			parent.set_state(parent.STATES.JUMP)
		
	# check if not falling, if not then do glide routine
	if !isFall and !sliding:
		# Go into falling if action not held
		if !parent.inputs[parent.INPUTS.ACTION] and !parent.inputs[parent.INPUTS.ACTION2] and !parent.inputs[parent.INPUTS.ACTION3]:
			parent.movement.x *= 0.25
			parent.animator.play("glideFall")
			parent.sprite.flip_h = (parent.direction < 0)
			# reset hitbox
			parent.set_hitbox(parent.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL))
			isFall = true
			parent.reflective = false


func state_physics_process(delta: float) -> void:
	# Change parent direction
	if parent.inputs[parent.INPUTS.XINPUT] != 0 and !sliding:
		parent.direction = parent.inputs[parent.INPUTS.XINPUT]
	
	
	
	
	# check if not falling, if not then do glide routine
	if !isFall and !sliding:
		# Turning
		# left
		if parent.direction > 0:
			if turnTimer >= 180:
				speedPreservation = abs(parent.movement.x)
			if turnTimer > 0:
				turnTimer -= 2.8125*delta*60
				parent.movement.x = speedPreservation*cos(deg_to_rad(turnTimer))
		# right
		elif parent.direction < 0:
			if turnTimer <= 0:
				speedPreservation = abs(parent.movement.x)
			if turnTimer < 180:
				turnTimer += 2.8125*delta*60
				parent.movement.x = speedPreservation*cos(deg_to_rad(turnTimer))
		
		turnTimer = clamp(turnTimer,0,180)
		
		# Animation
		var animSize = parent.animator.current_animation_length
		var offset = turnTimer/180
		
		parent.animator.advance(-parent.animator.current_animation_position+(animSize*offset))
		
		
		# set facing direction
		parent.sprite.flip_h = false
		
		# air movement
		if parent.pushingWall == 0:
			parent.movement.x = clamp(parent.movement.x+(glideAccel[int(parent.isSuper)]/GlobalFunctions.div_by_delta(delta)*parent.direction),-speedClamp,speedClamp)
		
		# Limit vertical movement
		if parent.movement.y < 0.5*60:
			parent.movement.y += glideGrav/GlobalFunctions.div_by_delta(delta)
		elif parent.movement.y > 0.5*60:
			parent.movement.y -= glideGrav/GlobalFunctions.div_by_delta(delta)
		
		# Go into sliding if on ground
		if parent.ground and !sliding and groundBuffer >= 1:
			parent.animator.play("glideSlide")
			if parent.movement.x != 0:
				parent.direction = sign(parent.movement.x)
			parent.sprite.flip_h = (parent.direction < 0)
			sliding = true
			parent.reflective = false
			$"../../SkidDustTimer".start(0.1)
			groundBuffer = 0
		
		# apply ground buffer
		elif parent.ground:
			groundBuffer = 1
		else:
			groundBuffer = 0
		
		# Go into wall cling if on wall
		parent.horizontalSensor.force_raycast_update()
		if parent.horizontalSensor.is_colliding() and !parent.ground:
			# set direction
			if parent.movement.x != 0:
				parent.direction = sign(parent.movement.x)
			parent.sprite.flip_h = (parent.direction < 0)
			
			parent.set_state(parent.STATES.CHARACTERACTION,
			                 parent.get_predefined_hitbox(PlayerChar.HITBOXES.GLIDE),
							 true,
							 KnucklesAvatar.CHAR_STATES.KNUCKLES_CLIMB)
			# play grab sound
			parent.sfx[26].play()
			parent.animator.play("climb")
			parent.movement = Vector2.ZERO
		
		# prevent getting stuck on corners
		parent.horizontalSensor.position.y = (parent.get_node("HitBox").shape.size.y/2)-1
		parent.horizontalSensor.force_raycast_update()
		if parent.horizontalSensor.is_colliding() and !parent.ground:
			parent.movement.x = 0
	
	# if sliding then do sliding routine
	elif sliding:
		
		if parent.movement.x != 0:
			parent.direction = sign(parent.movement.x)
		parent.movement.x = move_toward(parent.movement.x,0,friction/GlobalFunctions.div_by_delta(delta))
		
		# set direction
		parent.sprite.flip_h = (parent.direction < 0)
		if parent.movement.x == 0 and parent.lastActiveAnimation != "glideGetUp" and parent.ground:
			parent.cameraDragLerp = 1
			parent.set_predefined_hitbox(PlayerChar.HITBOXES.NORMAL)
			parent.animator.play("glideGetUp")
			# wait for animation to finish and check that the state is still the same
			await parent.animator.animation_finished
			if parent.get_state() == PlayerChar.STATES.CHARACTERACTION and sliding:
				parent.set_state(PlayerChar.STATES.NORMAL)
		
		# check if angle is default, if not then set movement to 0
		if !is_equal_approx(parent.snap_angle(parent.gravityAngle),parent.snap_angle(parent.global_rotation)):
			parent.movement.x = 0
		
		# check for ground, if not on ground go into falling
		if !parent.ground and groundBuffer >= 1:
			sliding = false
			parent.animator.play("glideFall")
			parent.sprite.flip_h = (parent.direction < 0)
			# reset hitbox
			parent.set_predefined_hitbox(PlayerChar.HITBOXES.NORMAL)
			isFall = true
		else:
			# ground buffer's needed to prevent the player immediately disconecting
			groundBuffer = 1
			parent.movement.y = 0
	
	# Do falling routine
	else:
		# regular movement
		if !parent.ground:
			# gravity
			parent.movement.y += parent.grv/GlobalFunctions.div_by_delta(delta)
			# movement (copied from air state)
			if (parent.movement.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
				if (abs(parent.movement.x) < parent.top):
					parent.movement.x = clamp(parent.movement.x+parent.air/GlobalFunctions.div_by_delta(delta)*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top)
			# set direction
			parent.sprite.flip_h = (parent.direction < 0)
			
		# landing
		if parent.ground and !landed:
			landed = true
			# play land sound
			parent.sfx[27].play()
			# set movement to nothign
			parent.movement = Vector2.ZERO
			parent.animator.play("land")
			# wait for landing animation to finish and check that the state is still the same
			await parent.animator.animation_finished
			if parent.get_state() == PlayerChar.STATES.GLIDE and isFall:
				parent.set_state(PlayerChar.STATES.NORMAL)


# create skid dust
func _on_SkidDustTimer_timeout():
	if parent.get_state() == PlayerChar.STATES.GLIDE:
		if !sliding or (parent.movement.x == 0 and parent.ground):
			$"../../SkidDustTimer".stop()
		elif parent.ground:
			var dust = parent.Particle.instantiate()
			dust.play("SkidDust")
			dust.global_position = parent.global_position+(Vector2.DOWN*8).rotated(deg_to_rad(parent.spriteRotation-90))
			dust.z_index = 10
			parent.get_parent().add_child(dust)
			parent.sfx[28].play()
