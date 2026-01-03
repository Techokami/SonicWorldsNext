extends PlayerState

var skid = false
# timer for looking up and down
# the original game uses 120 frames before panning over, so multiply delta by 0.5 for the same time
var lookTimer = 0
var actionPressed = false

# player idle animation array
# first array is player ID (Sonic, Tails, Knuckles), second array is the idle number
# note: idle is always played first
# you'll want to increase this for the number of playable characters
var playerIdles = [
# SONIC
["idle1","idle2","idle2","idle2","idle2","idle3",
"idle4","idle4","idle4","idle4","idle4","idle4","idle4","idle4","idle4","idle4",
"idle4","idle4","idle4","idle4","idle4","idle4","idle4","idle4","idle4","idle4",
"idle5"],
# Tails
["idle1"], # Note: Tails idle loops on idle one, to add more idles make sure to disable his idle1 loop
# Knuckles
["idle1"],
# Amy
["idle1","idle1","idle1","idle1","idle1","idle1","idle1","idle1","idle2","idle3"], # Note: like Tails, Amy loops on idle3
#Shadow
["idle1","idle2"]
]

func state_exit():
	skid = false
	parent.get_node("HitBox").position = parent.hitBoxOffset.normal
	parent.get_node("HitBox").shape.size = parent.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL)
	
	lookTimer = 0
	parent.sfx[29].stop()

func _on_SkidDustTimer_timeout():
	if parent.get_state() == PlayerChar.STATES.NORMAL:
		if !skid:
			$"../../SkidDustTimer".stop()
		else:
			var dust = parent.Particle.instantiate()
			dust.play("SkidDust")
			dust.global_position = parent.global_position+(Vector2.DOWN*16).rotated(deg_to_rad(parent.spriteRotation-90))
			parent.get_parent().add_child(dust)

# TODO Here's another function that is trying to do too many things. Break it up.
func state_process(delta: float) -> void:
	var animator: PlayerCharAnimationPlayer = parent.get_avatar().get_animator()
	# jumping / rolling and more (note, you'll want to adjust the other actions if your character does something different)
	if parent.any_action_pressed():
		if (parent.movement.x == 0 and parent.inputs[parent.INPUTS.YINPUT] > 0):
			animator.play("spinDash")
			parent.sfx[2].play()
			parent.sfx[2].pitch_scale = 1
			parent.spindashPower = 0
			animator.play("spinDash")
			parent.set_state(parent.STATES.SPINDASH)
		else:
			# Player cannot jump unless a ceiling check fails. Also block jumping if not grounded in
			# in case DW puts a character in the NORMAL state while they are airborne again.
			if !parent.check_for_ceiling() and parent.is_on_ground():
				# reset animations
				animator.play("RESET")
				parent.action_jump()
		return
	
	if parent.is_on_ground() and !skid:
		if parent.movement.x == 0:
			if (parent.inputs[parent.INPUTS.YINPUT] > 0):
				lookTimer = max(0,lookTimer+delta*0.5)
				if parent.lastActiveAnimation != "crouch":
					animator.play("crouch")
			elif (parent.inputs[parent.INPUTS.YINPUT] < 0):
				lookTimer = min(0,lookTimer-delta*0.5)
				if parent.lastActiveAnimation != "lookUp":
					animator.play("lookUp")
			else:
				# Idle pose animation
				
				# reset look timer
				lookTimer = 0
				
				# edge checking
				# set vertical sensors to check for objects
				
				var maskMemory = [parent.verticalSensorLeft.collision_mask,parent.verticalSensorRight.collision_mask]
				parent.verticalSensorLeft.set_collision_mask_value(13,true)
				parent.verticalSensorRight.set_collision_mask_value(13,true)
				#parent.verticalSensorLeft.force_raycast_update()
				#parent.verticalSensorRight.force_raycast_update()
				#parent.verticalSensorMiddle.force_raycast_update()
				
				var getL = parent.verticalSensorLeft.is_colliding()
				var getR = parent.verticalSensorRight.is_colliding()
				var getM = parent.verticalSensorMiddle.is_colliding()
				var getMEdge = parent.verticalSensorMiddleEdge.is_colliding()
				
				parent.verticalSensorLeft.collision_mask = maskMemory[0]
				parent.verticalSensorRight.collision_mask = maskMemory[1]
				
				# flip sensors
				if parent.get_direction_multiplier() < 0.0:
					getL = getR
					getR = parent.verticalSensorLeft.is_colliding()
				# No edge detected
				if getM or !parent.ground or parent.angle != parent.gravityAngle:
					# Play default idle animation
					if parent.isSuper and animator.has_animation("idle_super"):
						animator.play("idle_super")
					else:
						
						# loop through idle animations to see if there is an idle match
						var matchIdleCheck = false
						for i in playerIdles[parent.character-1]:
							if parent.lastActiveAnimation == i:
								matchIdleCheck = true
						
						if parent.lastActiveAnimation != "idle" and !matchIdleCheck or !animator.is_playing():
							animator.play("idle")
							# queue player specific idle animations
							for i in playerIdles[parent.character-1]:
								animator.queue(i)
				
				else:
					match (parent.character):
						
						Global.CHARACTERS.TAILS:
							if getR: # keep flipping until right sensor (relevent) isn't colliding
								parent.flip_movement_direction()
							animator.play("edge1")
						
						Global.CHARACTERS.KNUCKLES:
							if getR: # keep flipping until right sensor (relevent) isn't colliding
								parent.flip_movement_direction()
							if (animator.current_animation != "edge1" and
									animator.current_animation != "edge2"):
								animator.play("edge1")
								animator.queue("edge2")
								
						Global.CHARACTERS.AMY:
							if getR: # keep flipping until right sensor (relevent) isn't colliding
								parent.flip_movement_direction()
							#far edge
							if !getMEdge:
								animator.play("edge2")
							#normal edge
							else:
								animator.play("edge3")
						
						Global.CHARACTERS.SHADOW:
							if getL: # keep flipping until left sensor (relevent) isn't colliding
								parent.flip_movement_direction()
							animator.play("edge1")
						
						_: #default
							# super edge
							if parent.isSuper and animator.has_animation("edge_super"):
								animator.play("edge_super")
							# reverse edge
							elif !getL and getR:
								animator.play("edge3")
							# far edge
							elif !getMEdge:
								animator.play("edge2")
							# normal edge
							else:
								animator.play("edge1")
					
		elif sign(parent.pushingWall) == sign(parent.movement.x) and parent.pushingWall != 0:
			animator.play("push")
		elif(abs(parent.movement.x) < 6*60):
			animator.play("walk")
		elif(abs(parent.movement.x) < 10*60):
			animator.play("run")
		else:
			animator.play("peelOut")
	
	if parent.lastActiveAnimation == "crouch":
		parent.get_node("HitBox").shape.size = parent.get_predefined_hitbox(PlayerChar.HITBOXES.CROUCH)
		parent.get_node("HitBox").position = parent.hitBoxOffset.crouch
	else:
		parent.get_node("HitBox").shape.size = parent.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL)
		parent.get_node("HitBox").position = parent.hitBoxOffset.normal
	
	if parent.inputs[parent.INPUTS.XINPUT] != 0 and !skid:
		parent.set_direction_signed(parent.inputs[parent.INPUTS.XINPUT], false)
	elif parent.movement.x != 0 and skid:
		parent.set_direction_signed(signf(parent.movement.x), false)
	
	# water running
	parent.action_water_run_handle()
	pass
	
func state_physics_process(delta: float) -> void:
	var animator: PlayerCharAnimationPlayer = parent.get_avatar().get_animator()
	# enter roll if player pushes down while at speed
	if (parent.inputs[parent.INPUTS.YINPUT] == 1 and parent.inputs[parent.INPUTS.XINPUT] == 0 and abs(parent.movement.x) > 0.5*60):
		parent.set_state(parent.STATES.ROLL)
		animator.play("roll")
		parent.sfx[1].play()
		return
	
	# set air state
	if (!parent.ground):
		parent.set_state(parent.STATES.AIR)
		#Stop script
		return
	
	# skidding
	if !skid and sign(parent.inputs[parent.INPUTS.XINPUT]) != sign(parent.movement.x) and abs(parent.movement.x) >= 5*60 and parent.inputs[parent.INPUTS.XINPUT] != 0 and parent.horizontalLockTimer <= 0:
		skid = true
		parent.sfx[19].play()
		animator.play("skid")
		$"../../SkidDustTimer".start(0.1)
	
	elif skid:
		var inputX = parent.inputs[parent.INPUTS.XINPUT]
		
		if round(parent.movement.x/200) == 0 and sign(inputX) != sign(parent.movement.x):
			if animator.has_animation("skidTurn"):
				animator.play("skidTurn")
		
		if !animator.is_playing() or inputX == sign(parent.movement.x):
			skid = (round(parent.movement.x) != 0 and inputX != sign(parent.movement.x) and inputX != 0)
		
	parent.sprite.flip_h = (parent.get_direction_multiplier() < 0.0)
	
	parent.movement.y = min(parent.movement.y,0)
	
	# Camera look
	if abs(lookTimer) >= 1:
		parent.get_camera().look_amount += delta*4.0*signf(lookTimer)
	
	# Get the player's relative angle.
	var calcAngle = rad_to_deg(parent.angle-parent.gravityAngle)
	calcAngle = wrapf(calcAngle,0,360)
	
	# Apply slope factor, Sonic 1/2/CD/Mania style
	# If you want symmetry over Accuracy, the "46" in the line below should actually be "45"
	if (calcAngle >= 46 and calcAngle <= 315) or parent.movement.x !=0:
		parent.movement.x += (parent.get_physics().slope_factor*sin(parent.angle-parent.gravityAngle))/GlobalFunctions.div_by_delta(delta)
	
	# Apply slope factor, Sonic 3 style
		# parent.movement.x += (parent.get_physics().slop_factor*sin(parent.angle-parent.gravityAngle))/GlobalFunctions.div_by_delta(delta)
	
	# if speed below fall speed, slide down slopes and maybe also drop
	# If you want symmetry over Accuracy, the "46" in the line below should actually be "45"
	if (abs(parent.movement.x) < parent.get_physics().fall and calcAngle >= 46 and calcAngle <= 315):
		if (round(calcAngle) >= 90 and round(calcAngle) <= 270):
			parent.disconnect_from_floor()
		parent.horizontalLockTimer = 30.0/60.0
		
	# movement
	parent.action_move(delta)
	pass
