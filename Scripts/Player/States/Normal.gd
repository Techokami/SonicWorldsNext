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
["idle1"], # Note: tails idle loops on idle one, to add more idles make sure to disable his idle1 loop
# Knuckles
["idle1"],
# Amy
["idle1","idle2","idle2","idle2","idle2"]
]

func state_exit():
	skid = false
	parent.get_node("HitBox").position = parent.hitBoxOffset.normal
	parent.get_node("HitBox").shape.size = parent.currentHitbox.NORMAL
	
	lookTimer = 0
	parent.sfx[29].stop()

func _process(delta):
	
	# jumping / rolling and more (note, you'll want to adjust the other actions if your character does something different)
	if parent.any_action_pressed():
		if (parent.movement.x == 0 and parent.inputs[parent.INPUTS.YINPUT] > 0):
			parent.animator.play("spinDash")
			parent.sfx[2].play()
			parent.sfx[2].pitch_scale = 1
			parent.spindashPower = 0
			parent.animator.play("spinDash")
			parent.set_state(parent.STATES.SPINDASH)
		# peelout (Sonic only)
		elif (parent.movement.x == 0 and parent.inputs[parent.INPUTS.YINPUT] < 0 and parent.character == parent.CHARACTERS.SONIC):
			parent.sfx[2].play()
			parent.sfx[2].pitch_scale = 1
			parent.spindashPower = 0
			parent.set_state(parent.STATES.PEELOUT)
		else:
			# reset animations
			parent.animator.play("RESET")
			parent.action_jump()
			parent.set_state(parent.STATES.JUMP)
		return null
	
	if parent.ground and !skid:
		if parent.movement.x == 0:
			if (parent.inputs[parent.INPUTS.YINPUT] > 0):
				lookTimer = max(0,lookTimer+delta*0.5)
				if parent.lastActiveAnimation != "crouch":
					parent.animator.play("crouch")
			elif (parent.inputs[parent.INPUTS.YINPUT] < 0):
				lookTimer = min(0,lookTimer-delta*0.5)
				if parent.lastActiveAnimation != "lookUp":
					parent.animator.play("lookUp")
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
				if parent.direction < 0:
					getL = getR
					getR = parent.verticalSensorLeft.is_colliding()
				# No edge detected
				if getM or !parent.ground or parent.angle != parent.gravityAngle:
					# Play default idle animation
					if parent.isSuper and parent.animator.has_animation("idle_super"):
						parent.animator.play("idle_super")
					else:
						
						# loop through idle animations to see if there is an idle match
						var matchIdleCheck = false
						for i in playerIdles[parent.character]:
							if parent.lastActiveAnimation == i:
								matchIdleCheck = true
						
						if parent.lastActiveAnimation != "idle" and !matchIdleCheck or !parent.animator.is_playing():
							parent.animator.play("idle")
							# queue player specific idle animations
							for i in playerIdles[parent.character]:
								parent.animator.queue(i)
				
				else:
					match (parent.character):
						
						parent.CHARACTERS.TAILS:
							if getR: # keep flipping until right sensor (relevent) isn't colliding
								parent.direction = -parent.direction
							parent.animator.play("edge1")
						
						parent.CHARACTERS.KNUCKLES:
							if getR: # keep flipping until right sensor (relevent) isn't colliding
								parent.direction = -parent.direction
							if parent.animator.current_animation != "edge1" and parent.animator.current_animation != "edge2":
								parent.animator.play("edge1")
								parent.animator.queue("edge2")
						
						_: #default
							# super edge
							if parent.isSuper and parent.animator.has_animation("edge_super"):
								parent.animator.play("edge_super")
							# reverse edge
							elif !getL and getR:
								parent.animator.play("edge3")
							# far edge
							elif !getMEdge:
								parent.animator.play("edge2")
							# normal edge
							else:
								parent.animator.play("edge1")
					
		elif parent.pushingWall:
			parent.animator.play("push")
		elif(abs(parent.movement.x) < 6*60):
			parent.animator.play("walk")
		elif(abs(parent.movement.x) < 10*60):
			parent.animator.play("run")
		else:
			parent.animator.play("peelOut")
	
	if parent.lastActiveAnimation == "crouch":
		parent.get_node("HitBox").shape.size = parent.currentHitbox.CROUCH
		parent.get_node("HitBox").position = parent.hitBoxOffset.crouch
	else:
		parent.get_node("HitBox").position = parent.hitBoxOffset.normal
		parent.get_node("HitBox").shape.size = parent.currentHitbox.NORMAL
	
	if parent.inputs[parent.INPUTS.XINPUT] != 0 and !skid:
		parent.direction = parent.inputs[parent.INPUTS.XINPUT]
	elif parent.movement.x != 0 and skid:
		parent.direction = sign(parent.movement.x)
	
	# water running
	parent.action_water_run_handle()
	

func _physics_process(delta):
	
	# rolling
	if (parent.inputs[parent.INPUTS.YINPUT] == 1 and parent.inputs[parent.INPUTS.XINPUT] == 0 and abs(parent.movement.x) > 0.5*60):
		parent.set_state(parent.STATES.ROLL)
		parent.animator.play("roll")
		parent.sfx[1].play()
		return null
	
	# set air state
	if (!parent.ground):
		parent.set_state(parent.STATES.AIR)
		#Stop script
		return null
	
	# skidding
	if !skid and sign(parent.inputs[parent.INPUTS.XINPUT]) != sign(parent.movement.x) and abs(parent.movement.x) >= 5*60 and parent.inputs[parent.INPUTS.XINPUT] != 0 and parent.horizontalLockTimer <= 0:
		skid = true
		parent.sfx[19].play()
		parent.animator.play("skid")
		$"../../SkidDustTimer".start(0.1)
	
	elif skid:
		var inputX = parent.inputs[parent.INPUTS.XINPUT]
		
		if round(parent.movement.x/200) == 0 and sign(inputX) != sign(parent.movement.x):
			if parent.animator.has_animation("skidTurn"):
				parent.animator.play("skidTurn")
		
		if !parent.animator.is_playing() or inputX == sign(parent.movement.x):
			skid = (round(parent.movement.x) != 0 and inputX != sign(parent.movement.x) and inputX != 0)
		
	
	parent.sprite.flip_h = (parent.direction < 0)
	
	parent.movement.y = min(parent.movement.y,0)
	
	# Camera3D look
	if abs(lookTimer) >= 1:
		parent.camLookAmount += delta*4*sign(lookTimer)
	
	# Apply slope factor
	# ignore this if not moving for sonic 1 style slopes
	parent.movement.x += (parent.slp*sin(parent.angle-parent.gravityAngle))/GlobalFunctions.div_by_delta(delta)
	
	var calcAngle = rad_to_deg(parent.angle-parent.gravityAngle)
	if (calcAngle < 0):
		calcAngle += 360
	
	# if speed below fall speed, either drop or slide down slopes
	if (abs(parent.movement.x) < parent.fall and calcAngle >= 45 and calcAngle <= 315):
		if (round(calcAngle) >= 90 and round(calcAngle) <= 270):
			parent.disconect_from_floor()
		else:
			parent.horizontalLockTimer = 30.0/60.0
		
	# movement
	parent.action_move(delta)


func _on_SkidDustTimer_timeout():
	if parent.currentState == parent.STATES.NORMAL:
		if !skid:
			$"../../SkidDustTimer".stop()
		else:
			var dust = parent.Particle.instantiate()
			dust.play("SkidDust")
			dust.global_position = parent.global_position+(Vector2.DOWN*16).rotated(deg_to_rad(parent.spriteRotation-90))
			parent.get_parent().add_child(dust)
