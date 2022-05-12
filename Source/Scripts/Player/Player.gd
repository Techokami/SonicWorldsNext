extends PhysicsObject
const HITBOXESSONIC = {NORMAL = Vector2(9,19), ROLL = Vector2(7,14)}

#Sonic's Speed constants
var acc = 0.046875			#acceleration
var dec = 0.5				#deceleration
var frc = 0.046875			#friction (same as acc)
var rollfrc = frc*0.5		#roll friction
var rolldec = 0.125			#roll deceleration
var top = 6*60				#top horizontal speed
var toproll = 16*60			#top horizontal speed rolling
var slp = 0.125				#slope factor when walking/running
var slprollup = 0.078125		#slope factor when rolling uphill
var slprolldown = 0.3125		#slope factor when rolling downhill
var fall = 2.5*60			#tolerance ground speed for sticking to walls and ceilings

#Sonic's Airborne Speed Constants
var air = 0.09375			#air acceleration (2x acc)
var jmp = 6.5*60			#jump force (6 for knuckles)
var grv = 0.21875			#gravity
var releaseJmp = 4			#jump release velocity

var spindashPower = 0.0
var abilityUsed = false
var bounceReaction = 0 # for bubble shield
var invTime = 0
var supTime = 0
var super = false
var shoeTime = 0
var ringDisTime = 0 # ring collecting disable timer

# collision related values
var water = false
var pushingWall = 0

var enemyCounter = 0

# physics list
# order
# 0 Acceleration
# 1 Deceleration
# 2 Friction
# 3 Top Speed
# 4 Air Acceleration 
# 5 Rolling Friction 
# 6 Rolling Deceleration
# 7 Gravity
# 8 Jump
# 9 Jump release velocity

# 0 = Sonic, 1 = Tails, 2 = Knuckles, 3 = Shoes, 4 = Super Sonic

var lastPhysicsState = 0

var physicsList = [
# 0 Sonic
[0.046875, 0.5, 0.046875, 6*60, 0.09375, 0.046875*0.5, 0.125, 0.21875, 6.5*60, 4],
# 1 Tails
[0.046875, 0.5, 0.046875, 6*60, 0.09375, 0.046875*0.5, 0.125, 0.21875, 6.5*60, 4],
# 2 Knuckles
[0.046875, 0.5, 0.046875, 6*60, 0.09375, 0.046875*0.5, 0.125, 0.21875, 6*60, 4],
# 3 Shoes
[0.09375, 0.5, 0.09375, 12*60, 0.1875, 0.046875, 0.125, 0.21875, 6.5*60, 4],
# 4 Super Sonic
[0.1875, 1, 0.046875, 10*60, 0.375, 0.0234375, 0.125, 0.21875, 8*60, 4],
]

var waterPhysicsList = [
# 0 Sonic
[0.046875/2, 0.5/2, 0.046875/2, 6*60/2, 0.09375/2, 0.046875*0.5, 0.125, 0.0625, 3.5*60, 2],
# 1 Tails
[0.046875/2, 0.5/2, 0.046875/2, 6*60/2, 0.09375/2, 0.046875*0.5, 0.125, 0.0625, 3.5*60, 2],
# 2 Knuckles
[0.046875/2, 0.5/2, 0.046875/2, 6*60/2, 0.09375/2, 0.046875*0.5, 0.125, 0.0625, 3*60, 2],
# 3 Shoes
[0.046875/2, 0.5/2, 0.046875/2, 6*60/2, 0.09375/2, 0.046875*0.5, 0.125, 0.0625, 3.5*60, 2],
# 4 Super Sonic
[0.09375, 0.5, 0.046875, 5*60, 0.1875, 0.046875, 0.125, 0.0625, 3.5*60, 2],
]

# ================

var Ring = preload("res://Entities/Items/Ring.tscn")
var ringChannel = 0

var Particle = preload("res://Entities/Misc/GenericParticle.tscn")
var RotatingParticle = preload("res://Entities/Misc/RotatingParticle.tscn")

var superSprite = preload("res://Graphics/Players/SuperSonic.png")
onready var normalSprite = $Sprite/Sprite.texture
var sonicPal = preload("res://Shaders/SonicPalette.tres")

# ================

var lockTimer = 0
var spriteRotation = 0
var airControl = true

# States
enum STATES {NORMAL, AIR, JUMP, ROLL, SPINDASH, PEELOUT, ANIMATION, HIT, DIE, CORKSCREW, JUMPCANCEL, SUPER}
var currentState = STATES.NORMAL

# Shield variables
enum SHIELDS {NONE, NORMAL, ELEC, FIRE, BUBBLE}
var shield = SHIELDS.NONE
onready var magnetShape = $RingMagnet/CollisionShape2D

onready var stateList = $States.get_children()

onready var animator = $Sprite/PlayerAnimation
onready var sprite = $Sprite/Sprite
var lastActiveAnimation = ""

onready var shieldSprite = $Shields

# Camera
#onready var camera = get_node_or_null("Camera")
var camera = Camera2D.new()
var camDist = Vector2(32,64)
var camLookDist = [-104,88] # Up and Down
var camLookAmount = 0
var camLookOff = 0
var camAdjust = Vector2.ZERO
var cameraDragLerp = 0
var camLockPos = null
var camLockTime = 0

var rotatableSprites = ["walk", "run", "peelOut"]
var direction = scale.x

# Ground speed is mostly used for timing and animations, there isn't any functionality to it.
var groundSpeed = 0

enum INPUTS {XINPUT, YINPUT, ACTION, ACTION2, ACTION3, SUPER, PAUSE}
# Input control, 0 = 0ff, 1 = On
# (for held it's best to use inputs[INPUTS.ACTION] > 0)
# XInput and YInput are directions and are either -1, 0 or 1.
var inputs = [0,0,0,0,0,0,0]
# 0 = ai, 1 = player 1, 2 = player 2
var playerControl = 1

# Get sfx list
onready var sfx = $SFX.get_children()

# Player values
var shieldID = 0
var rings = 0

# How far in can the player can be towards the screen edge before they're clamped
var cameraMargin = 16

# ALL CODE IS TEMPORARY!
func _ready():
	# Disable and enable states
	set_state(currentState)
	Global.players.append(self)
	connect("connectFloor",self,"land_floor")
	connect("connectCeiling",self,"touch_ceiling")
	
	# Camera settings
	get_parent().call_deferred("add_child", (camera))
	camera.current = true
	var viewSize = get_viewport_rect().size
	camera.drag_margin_left =   camDist.x/viewSize.x
	camera.drag_margin_right =  camDist.x/viewSize.x
	camera.drag_margin_top =    camDist.y/viewSize.y
	camera.drag_margin_bottom = camDist.y/viewSize.y
	camera.drag_margin_h_enabled = true
	camera.drag_margin_v_enabled = true
	connect("positionChanged",self,"on_position_changed")
	camera.global_position = global_position
	
	# Checkpoints
	yield(get_tree(),"idle_frame")
	for i in Global.checkPoints:
		if Global.currentCheckPoint == i.checkPointID:
			global_position = i.global_position+Vector2(0,8)
	


func _input(event):
	if (playerControl != 0):
		if (event.is_action("gm_action")):
			inputs[INPUTS.ACTION] = calculate_input(event,"gm_action")

func calculate_input(event, action = "gm_action"):
	return int(event.is_action(action) or event.is_action_pressed(action))-int(event.is_action_released(action))


func _process(delta):
	if (ground):
		spriteRotation = rad2deg(angle)+90
	else:
		if (spriteRotation+90 >= 180):
			spriteRotation = max(90,spriteRotation-(168.75*delta))
		else:
			spriteRotation = min(360,spriteRotation+(168.75*delta))

	if (rotatableSprites.has(animator.current_animation)):
		sprite.rotation = deg2rad(stepify(spriteRotation,45)-90)-rotation
		#sprite.rotation = deg2rad(spriteRotation-90)-rotation
	else:
		sprite.rotation = -rotation

	if (lockTimer > 0):
		lockTimer -= delta
		inputs[INPUTS.XINPUT] = 0
		inputs[INPUTS.YINPUT] = 0

	# super / invincibility handling
	if (supTime > 0):
		if !super:
			supTime -= delta
		else:
			# Animate Palette
			sonicPal.set_shader_param("row",wrapf(sonicPal.get_shader_param("row")+delta*5,sonicPal.get_shader_param("palRows")-3,sonicPal.get_shader_param("palRows")))
			# check if ring count is greater then 0
			# deactivate if stage cleared
			if rings > 0 and Global.stageClearPhase == 0:
				rings -= delta
			else:
				# Deactivate super
				super = false
				supTime = 0
				sprite.texture = normalSprite
				switch_physics(0)
				
		if (supTime <= 0):
			if (shield != SHIELDS.NONE):
				shieldSprite.visible = true
			$InvincibilityBarrier.visible = false
			if Global.currentTheme == 0:
				#Global.music.stream_paused = false
				Global.music.play()
				Global.effectTheme.stop()
	else:
	# Deactivate super
		sonicPal.set_shader_param("row",clamp(sonicPal.get_shader_param("row")-delta*10,0,sonicPal.get_shader_param("palRows")-3))
	
	if (shoeTime > 0):
		shoeTime -= delta
		if (shoeTime <= 0):
			switch_physics()
			if Global.currentTheme == 1:
				#Global.music.stream_paused = false
				Global.music.play()
				Global.effectTheme.stop()

	if (invTime > 0 and currentState != STATES.HIT and currentState != STATES.DIE):
		visible = !visible
		invTime -= delta*60
		if (invTime <= 0):
			invTime = 0
			visible = true
	if (ringDisTime > 0):
		ringDisTime -= delta


	#Rotating stars
	if ($InvincibilityBarrier.visible):
		var stars = $InvincibilityBarrier.get_children()
		for i in stars:
			i.position = i.position.rotated(deg2rad(360*delta*2))
		if (fmod(Global.levelTime,0.1)+delta > 0.1):
			var star = RotatingParticle.instance()
			var starPart = star.get_node("GenericParticle")
			star.global_position = global_position
			starPart.direction = direction
			get_parent().add_child(star)
			var options = ["StarSingle","StarSinglePat2","default"]
			starPart.play(options[round(randf()*2)])
			starPart.frame = rand_range(0,6)

	# Animator
	match(animator.current_animation):
		"walk", "run", "peelOut":
			var duration = floor(max(0,8.0-abs(groundSpeed/60)))
			animator.playback_speed = (1.0/(duration+1))*(60/10)
		"roll":
			var duration = floor(max(0,4.0-abs(groundSpeed/60)))
			animator.playback_speed = (1.0/(duration+1))*(60/10)
		"push":
			var duration = floor(max(0,8.0-abs(groundSpeed/60)) * 4)
			animator.playback_speed = (1.0/(duration+1))*(60/10)
		"spinDash": #animate at 60fps (fps were animated at 0.1 seconds)
			animator.playback_speed = 60/10
		"dropDash":
			animator.playback_speed = 20/10
		_:
			animator.playback_speed = 1
	
	if animator.current_animation != "":
		lastActiveAnimation = animator.current_animation
		
	# Time over
	if Global.levelTime >= Global.maxTime:
		kill()
	
func _physics_process(delta):
	
	# Attacking is for rolling type animations
	var attacking = (animator.current_animation == "roll" or animator.current_animation == "dropDash" or animator.current_animation == "spinDash" )
	
	# physics sets
	# collid with solids if not rolling layer
	set_collision_mask_bit(15,!attacking)
	# damage mask bit
	set_collision_layer_bit(19,attacking)
	
	if (ground):
		groundSpeed = movement.x
	# wall detection
	if horizontalSensor.is_colliding() or is_on_wall():
		# give pushingWall a buffer otherwise this just switches on and off
		pushingWall = 2
		if sign(movement.x) == sign(horizontalSensor.cast_to.x):
			movement.x = 0
		
	elif pushingWall > 0:
		# count down pushingwall
		pushingWall -= 1

	if (playerControl != 0 and lockTimer <= 0):
		inputs[INPUTS.XINPUT] = -int(Input.is_action_pressed("gm_left"))+int(Input.is_action_pressed("gm_right"))
		inputs[INPUTS.YINPUT] = -int(Input.is_action_pressed("gm_up"))+int(Input.is_action_pressed("gm_down"))
	
	
	# Camera settings
	if (camera != null):
		
		# Lerp camera scroll based on if on floor
		var playerOffset = ((abs(global_position.y-camera.get_camera_position().y)*2)/camDist.y)
		
		cameraDragLerp = max(int(!ground),min(cameraDragLerp,playerOffset)-6*delta)
		
		# Looking/Lag
		# camLookDist is the distance, 0 is up, 1 is down
		camLookAmount = clamp(camLookAmount,-1,1)
		camLookOff = lerp(0,camLookDist[0],min(0,-camLookAmount))+lerp(0,camLookDist[1],min(0,camLookAmount))
		
		
		if camLookAmount != 0:
			var scrollSpeed = sign(camLookAmount)*delta*2
			if sign(camLookAmount - scrollSpeed) == sign(camLookAmount):
				camLookAmount -= sign(camLookAmount)*delta*2
			else:
				camLookAmount = 0
		
		# Camera Lock
		
		if camLockTime > 0:
#			if camLockPos == null:
#				camLockPos = camera.global_position-Vector2(0,camLookOff)
#			camLookOff = 0
			camLockTime -= delta
#		else:
#			camLockTime = 0
#			if camLockPos != null:
#				if camera.global_position.distance_to(global_position) >= 16:
#					camera.global_position = camera.global_position.move_toward(global_position,delta*16*60)
#				else:
#					camLockPos = null
		
		# Boundry handling
		# Stop movement at borders
		if (global_position.x < camera.limit_left+cameraMargin or global_position.x > camera.limit_right-cameraMargin):
			movement.x = 0
		
		# Death at border bottom
		if global_position.y > camera.limit_bottom:
			kill()
		
		# Clamp position
		global_position.x = clamp(global_position.x,camera.limit_left+cameraMargin,camera.limit_right-cameraMargin)
	
	# Water
	if Global.waterLevel != null and currentState != STATES.DIE:
		# Enter water
		if global_position.y > Global.waterLevel and !water:
			water = true
			switch_physics(lastPhysicsState,true)
			movement.x *= 0.5
			movement.y *= 0.25
			sfx[17].play()
			var splash = Particle.instance()
			splash.global_position = Vector2(global_position.x,Global.waterLevel-16)
			splash.play("Splash")
			splash.z_index = sprite.z_index+10
			get_parent().add_child(splash)
			match (shield):
				SHIELDS.ELEC, SHIELDS.FIRE:
					set_shield(SHIELDS.NONE)
		# Exit water
		if global_position.y < Global.waterLevel and water:
			water = false
			switch_physics(lastPhysicsState,false)
			movement.y *= 2
			sfx[17].play()
			var splash = Particle.instance()
			splash.global_position = Vector2(global_position.x,Global.waterLevel-16)
			splash.play("Splash")
			splash.z_index = sprite.z_index+10
			get_parent().add_child(splash)
			

func set_state(newState, forceMask = Vector2.ZERO):
	for i in stateList:
		i.set_process(i == stateList[newState])
		i.set_physics_process(i == stateList[newState])
		i.set_process_input(i == stateList[newState])
	
	if currentState != newState:
		if stateList[currentState].has_method("state_exit"):
			stateList[currentState].state_exit()
		if stateList[newState].has_method("state_activated"):
			stateList[newState].state_activated()
		currentState = newState
	if ground:
		enemyCounter = 0
	
	var shapeChangeCheck = $HitBox.shape.extents
	var forcePoseChange = Vector2.ZERO
	
	if (forceMask == Vector2.ZERO):
		match(newState):
			STATES.JUMP, STATES.ROLL:
				# adjust y position
				forcePoseChange = ((HITBOXESSONIC.ROLL-$HitBox.shape.extents)*Vector2.UP).rotated(rotation)
				
				# change hitbox size
				$HitBox.shape.extents = HITBOXESSONIC.ROLL
			_:
				# adjust y position
				forcePoseChange = ((HITBOXESSONIC.NORMAL-$HitBox.shape.extents)*Vector2.UP).rotated(rotation)
				
				# change hitbox size
				$HitBox.shape.extents = HITBOXESSONIC.NORMAL
	else:
		# adjust y position
		forcePoseChange = ((forceMask-$HitBox.shape.extents)*Vector2.UP).rotated(rotation)
		# change hitbox size
		$HitBox.shape.extents = forceMask
	
	position += forcePoseChange
	
	#cam_update()
	
	
	sprite.get_node("DashDust").visible = false
	#update_sensors()
	# snap to floor if old shape is smaller then new shape
#	if (shapeChangeCheck.y < $HitBox.shape.extents.y):
#		var getFloor = get_closest_sensor(floorCastLeft,floorCastRight)
#		if (getFloor):
#			position += getFloor.get_collision_point()-getFloor.global_position-($HitBox.shape.extents*Vector2(0,1)).rotated(rotation)

# set shields
func set_shield(shieldID):
	magnetShape.shape.radius = 0
	shield = shieldID
	shieldSprite.visible = !super
	match (shield):
		SHIELDS.NORMAL:
			shieldSprite.play("Default")
			sfx[5].play()
		SHIELDS.ELEC:
			shieldSprite.play("Elec")
			sfx[10].play()
			magnetShape.shape.radius = 64
		SHIELDS.FIRE:
			shieldSprite.play("Fire")
			sfx[11].play()
		SHIELDS.BUBBLE:
			shieldSprite.play("Bubble")
			sfx[12].play()
		_: # disable
			shieldSprite.visible = false

func action_jump(animation = "roll", airJumpControl = true):
	animator.play(animation)
	movement.y = -jmp
	sfx[0].play()
	airControl = airJumpControl
	cameraDragLerp = 1
	set_state(STATES.JUMP)


func hit_player(damagePoint = global_position, damageType = 0, soundID = 6):
	if (currentState != STATES.HIT and invTime <= 0 and supTime <= 0):
		movement.x = sign(global_position.x-damagePoint.x)*2*60
		movement.y = -4*60
		if (movement.x == 0):
			movement.x = 2*60

		ground = false
		disconect_from_floor()
		set_state(STATES.HIT)
		invTime = 120
		# Ring loss
		if (shield == SHIELDS.NONE and rings > 0):
			sfx[9].play()
			ringDisTime = 64/Global.originalFPS
			var ringCount = 0
			var ringAngle = 101.25
			var ringAlt = false
			var ringSpeed = 4
			while (ringCount < min(rings,32)):
				# Create ring
				var ring = Ring.instance()
				ring.global_position = global_position
				ring.scattered = true
				ring.velocity.y = -sin(deg2rad(ringAngle))*ringSpeed*Global.originalFPS
				ring.velocity.x = cos(deg2rad(ringAngle))*ringSpeed*Global.originalFPS

				if (ringAlt):
					ring.velocity.x *= -1
					ringAngle += 22.5
				ringAlt = !ringAlt
				ringCount += 1
				# if we're on the second circle, decrease the speed
				if (ringCount == 16):
					ringSpeed = 2
					ringAngle == 101.25 # Reset angle
				get_parent().add_child(ring)

			rings = 0
		elif shield == SHIELDS.NONE:
			kill()
		else:
			sfx[soundID].play()
		# Disable Shield
		set_shield(SHIELDS.NONE)
		return true
	return false

func kill():
	if currentState != STATES.DIE:
		disconect_from_floor()
		super = false
		supTime = 0
		collision_layer = 0
		collision_mask = 0
		z_index = 100
		movement = Vector2(0,-7*60)
		set_state(STATES.DIE,HITBOXESSONIC.NORMAL)
		animator.play("die")
		sfx[6].play()

func get_ring():
	rings += 1
	sfx[7+ringChannel].play()
	sfx[7].play()
	ringChannel = int(!ringChannel)

func touch_ceiling():
	if getVert != null:
		var getAngle = wrapf(-rad2deg(getVert.get_collision_normal().angle())-90,0,360)
		if (getAngle > 225 or getAngle < 135):
			angle = getAngle
			rotation = snap_angle(-deg2rad(getAngle))
			update_sensors()
			movement = -Vector2(movement.y*sign(sin(deg2rad(getAngle))),0)
			ground = true
			return true
	movement.y = 0

func land_floor():
	
	abilityUsed = false
	# landing movement calculation
	
	# recalculate ground angle
	var calcAngle = wrapf(rad2deg(angle),0,360)
	
	# check not shallow
	if (calcAngle >= 22.5 and calcAngle <= 337.5 and abs(movement.x) < movement.y):
		# check half steep
		if (calcAngle < 45 or calcAngle > 315):
			movement.x = movement.y*0.5*sign(sin(angle))
		# else do full steep
		else:
			movement.x = movement.y*sign(sin(angle))


# clean animation
func _on_PlayerAnimation_animation_started(anim_name):
	if (sprite != null):
		sprite.flip_v = false
		sprite.offset = Vector2(0,-4)
		animator.advance(0)

func switch_physics(physicsRide = -1, isWater = water):
	var getList = physicsList[max(0,physicsRide)]
	if isWater:
		getList = waterPhysicsList[max(0,physicsRide)]
	acc = getList[0]
	dec = getList[1]
	frc = getList[2]
	top = getList[3]
	air = getList[4]
	rollfrc = getList[5]
	rolldec = getList[6]
	grv = getList[7]
	jmp = getList[8]
	releaseJmp = getList[9]
	if physicsRide >= 0:
		lastPhysicsState = physicsRide



func _on_SparkleTimer_timeout():
	if super && abs(movement.x) >= top:
		var sparkle = Particle.instance()
		sparkle.global_position = global_position
		sparkle.play("Super")
		get_parent().add_child(sparkle)

func on_position_changed():
	cam_update(true)

func cam_update(forceMove = false):
	# Cancel camera movement
	if currentState == STATES.DIE:
		return false
	# Camera vertical drag
	var viewSize = get_viewport_rect().size
	
	camera.drag_margin_top =    lerp(0,camDist.y/viewSize.y,cameraDragLerp)
	camera.drag_margin_bottom = camera.drag_margin_top
	
	# Extra drag margin for rolling
	match($HitBox.shape.extents):
		HITBOXESSONIC.ROLL:
			camAdjust = Vector2(0,-5)
		_:
			camAdjust = Vector2.ZERO

	# Camera lock
	var getPos = global_position+Vector2(0,camLookOff)+camAdjust
	if camLockTime <= 0 && forceMove || camera.global_position.distance_to(getPos) <= 16:
		# clamped speed camera
		camera.global_position = camera.global_position.move_toward(getPos,16*60*get_physics_process_delta_time())
		# uncomment below for immediate camera
		#camera.global_position = getPos

func lock_camera(time = 1):
	camLockTime = max(time,camLockTime)
