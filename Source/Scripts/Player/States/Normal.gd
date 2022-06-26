extends "res://Scripts/Player/State.gd"

var skid = false
# timer for looking up and down
# the original game uses 120 frames before panning over, so multiply delta by 0.5 for the same time
var lookTimer = 0
var actionPressed = false

func state_exit():
	skid = false
	if parent.crouchBox:
		parent.crouchBox.disabled = true
	parent.get_node("HitBox").disabled = false
	lookTimer = 0

func _process(delta):

	if parent.inputs[parent.INPUTS.ACTION] == 1:
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
				var getL = parent.verticalSensorLeft.is_colliding()
				var getR = parent.verticalSensorRight.is_colliding()
				var getM = parent.verticalSensorMiddle.is_colliding()
				var getMEdge = parent.verticalSensorMiddleEdge.is_colliding()
				# flip sensors
				if parent.direction < 0:
					getL = getR
					getR = parent.verticalSensorLeft.is_colliding()
				if getM || !parent.ground:
					# Play default idle animation
					if parent.super and parent.animator.has_animation("idle_super"):
						parent.animator.play("idle_super")
					else:
						parent.animator.play("idle")
				# super edge
				elif parent.super and parent.animator.has_animation("edge_super"):
					parent.animator.play("edge_super")
				elif !getL and getR: # reverse edge
					parent.animator.play("edge3")
				elif !getMEdge: # far edge
					parent.animator.play("edge2")
				else: # normal edge
					parent.animator.play("edge1")
					
		elif parent.pushingWall:
			parent.animator.play("push")
		elif(abs(parent.movement.x) < 6*60):
			parent.animator.play("walk")
		elif(abs(parent.movement.x) < 10*60):
			parent.animator.play("run")
		else:
			parent.animator.play("peelOut")
		
	parent.crouchBox.disabled = (parent.lastActiveAnimation != "crouch")
	parent.get_node("HitBox").disabled = !parent.crouchBox.disabled
	
	if parent.inputs[parent.INPUTS.XINPUT] != 0 and !skid:
		parent.direction = parent.inputs[parent.INPUTS.XINPUT]
	elif parent.movement.x != 0 and skid:
		parent.direction = sign(parent.movement.x)

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
		$SkidDustTimer.start(0.1)
	
	elif skid:
		var inputX = parent.inputs[parent.INPUTS.XINPUT]
		
		if round(parent.movement.x/200) == 0 and sign(inputX) != sign(parent.movement.x):
			parent.animator.play("skidTurn")
		
		if !parent.animator.is_playing() || inputX == sign(parent.movement.x):
			skid = (round(parent.movement.x) != 0 and inputX != sign(parent.movement.x) and inputX != 0)
		
	
	parent.sprite.flip_h = (parent.direction < 0)
	
	parent.movement.y = min(parent.movement.y,0)
	
	# Camera look
	if abs(lookTimer) >= 1:
		parent.camLookAmount += delta*4*sign(lookTimer)
	
	# Apply slope factor
	# ignore this if not moving for sonic 1 style slopes
	parent.movement.x += (parent.slp*sin(parent.angle))/delta
	
	var calcAngle = rad2deg(parent.angle)
	if (calcAngle < 0):
		calcAngle += 360
	
	# if speed below fall speed, either drop or slide down slopes
	if (abs(parent.movement.x) < parent.fall and calcAngle >= 45 and calcAngle <= 315):
		if (round(calcAngle) >= 90 and round(calcAngle) <= 270):
			parent.disconect_from_floor()
			#parent.ground = false
		else:
			parent.horizontalLockTimer = 30.0/60.0
		
	# movement
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		if (parent.movement.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (sign(parent.movement.x) == parent.inputs[parent.INPUTS.XINPUT]):
				if (abs(parent.movement.x) < parent.top):
					parent.movement.x = clamp(parent.movement.x+parent.acc/delta*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top)
			else:
				# reverse direction
				parent.movement.x += parent.dec/delta*parent.inputs[parent.INPUTS.XINPUT]
				# implament weird turning quirk
				if (sign(parent.movement.x) != sign(parent.movement.x-parent.dec/delta*parent.inputs[parent.INPUTS.XINPUT])):
					parent.movement.x = 0.5*60*sign(parent.movement.x)
	else:
		if (parent.movement.x != 0):
			# check that decreasing movement won't go too far
			if (sign(parent.movement.x - (parent.frc/delta)*sign(parent.movement.x)) == sign(parent.movement.x)):
				parent.movement.x -= (parent.frc/delta)*sign(parent.movement.x)
			else:
				parent.movement.x -= parent.movement.x


func _on_SkidDustTimer_timeout():
	if !skid:
		$SkidDustTimer.stop()
	else:
		var dust = parent.Particle.instance()
		dust.play("SkidDust")
		dust.global_position = parent.global_position+(Vector2.DOWN*16).rotated(deg2rad(parent.spriteRotation-90))
		parent.get_parent().add_child(dust)
