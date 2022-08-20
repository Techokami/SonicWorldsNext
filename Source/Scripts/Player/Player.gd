extends PhysicsObject
const HITBOXESSONIC = {NORMAL = Vector2(9,19), ROLL = Vector2(7,14), CROUCH = Vector2(9,11), GLIDE = Vector2(10,10)}
const HITBOXESTAILS = {NORMAL = Vector2(9,15), ROLL = Vector2(7,14), CROUCH = Vector2(9,9.5), GLIDE = Vector2(10,10)}
const HITBOXESKNUCKLES = {NORMAL = Vector2(9,19), ROLL = Vector2(7,14), CROUCH = Vector2(9,11), GLIDE = Vector2(10,10)}
var currentHitbox = HITBOXESSONIC

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

# water settings
var water = false
var defaultAirTime = 30 # 30 seconds
var panicTime = 12 # start count down at 12 seconds
var airWarning = 5 # time between air meter sound
var airTimer = defaultAirTime

# collision related values
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

enum CHARACTERS {SONIC, TAILS, KNUCKLES}
var character = CHARACTERS.SONIC

# 0 = Sonic, 1 = Tails, 2 = Knuckles, 3 = Shoes, 4 = Super Sonic

var physicsList = [
# 0 Sonic
[0.046875, 0.5, 0.046875, 6*60, 0.09375, 0.046875*0.5, 0.125, 0.21875, 6.5*60, 4],
# 1 Tails
[0.046875, 0.5, 0.046875, 6*60, 0.09375, 0.046875*0.5, 0.125, 0.21875, 6.5*60, 4],
# 2 Knuckles
[0.046875, 0.5, 0.046875, 6*60, 0.09375, 0.046875*0.5, 0.125, 0.21875, 6*60, 4],
# 3 Shoes (remove *0.5 for original rolling friction)
[0.09375, 0.5, 0.09375, 12*60, 0.1875, 0.046875*0.5, 0.125, 0.21875, 6.5*60, 4],
# 4 Super Sonic
[0.1875, 1, 0.046875, 10*60, 0.375, 0.0234375, 0.125, 0.21875, 8*60, 4],
# 5 Super Tails
[0.09375, 0.75, 0.046875, 8*60, 0.1875, 0.0234375, 0.125, 0.21875, 6.5*60, 4],
# 6 Super Knuckles
[0.09375, 0.75, 0.046875, 8*60, 0.1875, 0.0234375, 0.125, 0.21875, 6*60, 4],
# 7 Shoes Knuckles (small jump) (remove *0.5 for original rolling friction)
[0.09375, 0.5, 0.09375, 12*60, 0.1875, 0.046875*0.5, 0.125, 0.21875, 6*60, 4],
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
# 5 Super Tails
[0.046875, 0.375, 0.046875, 4*60, 0.09375, 0.0234375, 0.125, 0.0625, 3.5*60, 2],
# 6 Super Knuckles
[0.046875, 0.375, 0.046875, 4*60, 0.09375, 0.0234375, 0.125, 0.0625, 3*60, 2],
# 7 Shoes Knuckles (small jump)
[0.046875/2, 0.5/2, 0.046875/2, 6*60/2, 0.09375/2, 0.046875*0.5, 0.125, 0.0625, 3*60, 2],
]

# ================

var Ring = preload("res://Entities/Items/Ring.tscn")
var ringChannel = 0

var Particle = preload("res://Entities/Misc/GenericParticle.tscn")
var Bubble = preload("res://Entities/Misc/Bubbles.tscn")
var CountDown = preload("res://Entities/Misc/CountDownTimer.tscn")
var RotatingParticle = preload("res://Entities/Misc/RotatingParticle.tscn")

var superSprite = load("res://Graphics/Players/SuperSonic.png")
onready var normalSprite = $Sprite/Sprite.texture
var playerPal = preload("res://Shaders/PlayerPalette.tres")

# ================

var horizontalLockTimer = 0
var spriteRotation = 0
var airControl = true

# States
enum STATES {NORMAL, AIR, JUMP, ROLL, SPINDASH, PEELOUT, ANIMATION, HIT, DIE, CORKSCREW, JUMPCANCEL, SUPER, FLY, RESPAWN, HANG, GLIDE, WALLCLIMB}
var currentState = STATES.NORMAL
onready var hitBoxOffset = {normal = $HitBox.position, crouch = $HitBox.position}
var crouchBox = null

# Shield variables
enum SHIELDS {NONE, NORMAL, FIRE, ELEC, BUBBLE}
var shield = SHIELDS.NONE
onready var magnetShape = $RingMagnet/CollisionShape2D
onready var shieldSprite = $Shields
var reflective = false # used for reflecting projectiles

# State array
onready var stateList = $States.get_children()


# Animation related
onready var animator = $Sprite/PlayerAnimation
onready var sprite = $Sprite/Sprite
onready var spriteControler = $Sprite
var lastActiveAnimation = ""
var defaultSpriteOffset = Vector2.ZERO

# Camera
# onready var camera = get_node_or_null("Camera")
var camera = Camera2D.new()
var camDist = Vector2(32,64)
var camLookDist = [-104,88] # Up and Down
var camLookAmount = 0
var camLookOff = 0
var camAdjust = Vector2.ZERO
var cameraDragLerp = 0
var camLockTime = 0

# boundries
var limitLeft = 0
var limitRight = 0
var limitTop = 0
var limitBottom = 0

var rotatableSprites = ["walk", "run", "peelOut"]
var direction = scale.x

# Ground speed is mostly used for timing and animations, there isn't any functionality to it.
var groundSpeed = 0

enum INPUTS {XINPUT, YINPUT, ACTION, ACTION2, ACTION3, PAUSE}
# Input control, 0 = 0ff, 1 = pressed, 2 = held
# (for held it's best to use inputs[INPUTS.ACTION] > 0)
# XInput and YInput are directions and are either -1, 0 or 1.
var inputs = [0,0,0,0,0,0,0]
const INPUTACTIONS_P1 = [["gm_left","gm_right"],["gm_up","gm_down"],"gm_action","gm_action2","gm_action3","gm_pause"]
const INPUTACTIONS_P2 = [["gm_left_P2","gm_right_P2"],["gm_up_P2","gm_down_P2"],"gm_action_P2","gm_action2_P2","gm_action3_P2","gm_pause_P2"]
var inputActions = INPUTACTIONS_P1
# 0 = ai, 1 = player 1, 2 = player 2
var playerControl = 1

var partner = null
var partnerPanic = 0

const RESPAWN_DEFAULT_TIME = 5
var respawnTime = RESPAWN_DEFAULT_TIME

const DEFAULT_PLAYER2_CONTROL_TIME = 10
var partnerControlTime = DEFAULT_PLAYER2_CONTROL_TIME

# defaults
onready var defaultLayer = collision_layer
onready var defaultMask = collision_mask
onready var defaultZIndex = z_index
# Input memory has 2 arrays, first is the timer, second is the input index
# inputMemory[5][INPUT.XINPUT]
var inputMemory = []
const INPUT_MEMORY_LENGTH = 20

var Player = load("res://Entities/MainObjects/Player.tscn")
var tailsAnimations = preload("res://Graphics/Players/PlayerAnimations/Tails.tscn")
var knucklesAnimations = preload("res://Graphics/Players/PlayerAnimations/Knuckles.tscn")

# Get sfx list
onready var sfx = $SFX.get_children()

# Player values
var rings = 0
var ring1upCounter = 100

# How far in can the player can be towards the screen edge before they're clamped
var cameraMargin = 16

# Gimmick related
var poleGrabID = null

# Enemy related
signal enemy_bounced

func _ready():
	# Disable and enable states
	set_state(currentState)
	Global.players.append(self)
	var _con = connect("connectFloor",self,"land_floor")
	_con = connect("connectCeiling",self,"touch_ceiling")
	
	# Camera settings
	get_parent().call_deferred("add_child", (camera))
	camera.current = (playerControl == 1)
	var viewSize = get_viewport_rect().size
	camera.drag_margin_left =   camDist.x/viewSize.x
	camera.drag_margin_right =  camDist.x/viewSize.x
	camera.drag_margin_top =    camDist.y/viewSize.y
	camera.drag_margin_bottom = camDist.y/viewSize.y
	camera.drag_margin_h_enabled = true
	camera.drag_margin_v_enabled = true
	_con = connect("positionChanged",self,"on_position_changed")
	camera.global_position = global_position
	
	# Tails carry stuff
	$TailsCarryBox/HitBox.disabled = true
	
	
	# verify that we're not an ai
	if playerControl == 1:
		# input memory
		for _i in range(INPUT_MEMORY_LENGTH):
			inputMemory.append(inputs.duplicate(true))
		# Partner (if player character 2 isn't none)
		if Global.PlayerChar2 != Global.CHARACTERS.NONE:
			partner = Player.instance()
			partner.playerControl = 0
			partner.z_index = z_index-1
			get_parent().call_deferred("add_child", (partner))
			partner.global_position = global_position+Vector2(-24,0)
			partner.partner = self
			partner.character = Global.PlayerChar2-1
			partner.inputActions = INPUTACTIONS_P2
		
		# set my character
		character = Global.PlayerChar1-1
		
		# set palettes
		match (character):
			CHARACTERS.SONIC:
				playerPal.set_shader_param("amount",3)
				playerPal.set_shader_param("palRows",9)
				playerPal.set_shader_param("row",0)
				playerPal.set_shader_param("paletteTexture",load("res://Graphics/Palettes/SuperSonicPal.png"))
		
			CHARACTERS.TAILS:
				playerPal.set_shader_param("amount",6)
				playerPal.set_shader_param("palRows",10)
				playerPal.set_shader_param("row",0)
				playerPal.set_shader_param("paletteTexture",load("res://Graphics/Palettes/SuperTails.png"))
		
			CHARACTERS.KNUCKLES:
				playerPal.set_shader_param("amount",3)
				playerPal.set_shader_param("palRows",11)
				playerPal.set_shader_param("row",0)
				playerPal.set_shader_param("paletteTexture",load("res://Graphics/Palettes/SuperKnuckles.png"))
	
	
	# Checkpoints
	yield(get_tree(),"idle_frame")
	for i in Global.checkPoints:
		if Global.currentCheckPoint == i.checkPointID:
			global_position = i.global_position+Vector2(0,8)
			camera.global_position = i.global_position+Vector2(0,8)
			Global.levelTime = Global.checkPointTime
		else:
			Global.levelTime = 0
	
	
	
	# Character settings
	match (character):
		CHARACTERS.TAILS:
			# Set sprites
			currentHitbox = HITBOXESTAILS
			get_node("Sprite").queue_free()
			yield(get_tree(),"idle_frame")
			var tails = tailsAnimations.instance()
			add_child(tails)
			sprite = tails.get_node("Sprite")
			animator = tails.get_node("PlayerAnimation")
			spriteControler = tails
		CHARACTERS.KNUCKLES:
			# Set sprites
			currentHitbox = HITBOXESKNUCKLES
			get_node("Sprite").queue_free()
			yield(get_tree(),"idle_frame")
			var knuckles = knucklesAnimations.instance()
			add_child(knuckles)
			sprite = knuckles.get_node("Sprite")
			animator = knuckles.get_node("PlayerAnimation")
			spriteControler = knuckles
	
	# run switch physics to ensure character specific physics
	switch_physics()
	
	# Set hitbox
	$HitBox.shape.extents = currentHitbox.NORMAL
	
	# connect animator
	animator.connect("animation_started",self,"_on_PlayerAnimation_animation_started")
	defaultSpriteOffset = sprite.offset
	
	
	crouchBox = get_node_or_null("Sprite/CrouchBox")
	if crouchBox != null:
		crouchBox.get_parent().remove_child(crouchBox)
		add_child(crouchBox)
		crouchBox.disabled = true
		hitBoxOffset.crouch = crouchBox.position
	
	# reset camera limits
	limitLeft = Global.hardBorderLeft
	limitRight = Global.hardBorderRight
	limitTop = Global.hardBorderTop
	limitBottom = Global.hardBorderBottom
	snap_camera_to_limits()



# 0 not pressed, 1 pressed, 2 held (best to do > 0 when checking input), -1 released
func calculate_input(event, action = "gm_action"):
	return int(event.is_action(action) or event.is_action_pressed(action))-int(event.is_action_released(action))


func _process(delta):
	
	# Player 1 input settings and partner AI
	if playerControl == 1:
		# Input memory
		for i in range(INPUT_MEMORY_LENGTH-1):
			for j in range(inputs.size()):
				inputMemory[INPUT_MEMORY_LENGTH-1-i][j] = inputMemory[INPUT_MEMORY_LENGTH-i-2][j]
		# set immediate inputs
		for i in range(inputs.size()):
			inputMemory[0][i] = inputs[i]
		
		# Partner ai logic
		if partner != null:
			# Check if partner panic
			if partnerPanic <= 0:
				if partner.playerControl == 0:
					partner.inputs = inputMemory[INPUT_MEMORY_LENGTH-1]
				
				# x distance difference check, try to go to the partner
				if (partner.inputs[INPUTS.XINPUT] == 0 and partner.inputs[INPUTS.YINPUT] == 0
					or global_position.distance_to(partner.global_position) > 48 and round(movement.x/300) == 0
					) and abs(global_position.x-partner.global_position.x) >= 32:
					partner.inputs[INPUTS.XINPUT] = sign(global_position.x - partner.global_position.x)
				
				# Jump if pushing a wall, slower then half speed, on a flat surface and is either normal or jumping
				if (partner.currentState == STATES.NORMAL or partner.currentState == STATES.JUMP) and abs(partner.movement.x) < top/2 and snap_angle(partner.angle) == 0 or (partner.pushingWall and !pushingWall):
					# check partners position, only jump ever 0.25 seconds (prevent jump spam)
					if global_position.y+32 < partner.global_position.y and partner.inputs[INPUTS.ACTION] == 0 and partner.ground and ground and (fmod(Global.globalTimer,0.25)+delta > 0.25):
						partner.inputs[INPUTS.ACTION] = 1
					elif global_position.y < partner.global_position.y and ground and !partner.ground:
						partner.inputs[INPUTS.ACTION] = 2
			# panic
			else:
				if global_position.distance_to(partner.global_position) <= 48 or partner.direction != sign(global_position.x - partner.global_position.x):
					partnerPanic = 0
				partner.inputs[INPUTS.XINPUT] = 0
				if round(partner.movement.x) == 0:
					partnerPanic -= delta
					partner.inputs[INPUTS.YINPUT] = 1
					# press action every 0.4 ticks
					if fmod(partnerPanic,0.4)+delta > 0.4:
						partner.inputs[INPUTS.ACTION] = 1
					
			
			# Panic
			# if partner is locked, and stopped then do a spindash
			# panic for 128 frames before letting go of spindash
			if partner.horizontalLockTimer > 0 and partner.currentState == STATES.NORMAL and global_position.distance_to(partner.global_position) > 48:
				partnerPanic = 128/60
				
	# respawn mechanics
	else:
		if $ScreenCheck.is_on_screen():
			respawnTime = RESPAWN_DEFAULT_TIME
		else:
			if respawnTime > 0:
				respawnTime -= delta
			else:
				respawn()
				
			
	
	# Sprite rotation handling
	if (ground):
		spriteRotation = rad2deg(angle)+rad2deg(gravityAngle)+90
	else:
		if (spriteRotation+90 >= 180):
			spriteRotation = max(90,spriteRotation-(168.75*delta))
		else:
			spriteRotation = min(360,spriteRotation+(168.75*delta))
	
	# set the sprite to match the sprite rotation variable if it's in the rotatable Sprites list
	if (rotatableSprites.has(animator.current_animation)):
		sprite.rotation = deg2rad(stepify(spriteRotation,45)-90)-rotation-gravityAngle
		# uncomment this next line out for smooth rotation (you should remove the above line too)
		#sprite.rotation = deg2rad(spriteRotation-90)-rotation
	else:
		sprite.rotation = -rotation+gravityAngle

	spriteControler.global_position = global_position.round()

	if (horizontalLockTimer > 0):
		horizontalLockTimer -= delta
		inputs[INPUTS.XINPUT] = 0
		#inputs[INPUTS.YINPUT] = 0

	# super / invincibility handling
	if (supTime > 0):
		if !super:
			supTime -= delta
		else:
			$InvincibilityBarrier.visible = false
			# Animate Palette
			match character:
				CHARACTERS.SONIC:
					playerPal.set_shader_param("row",wrapf(playerPal.get_shader_param("row")+delta*5,playerPal.get_shader_param("palRows")-3,playerPal.get_shader_param("palRows")))
				CHARACTERS.TAILS:
					playerPal.set_shader_param("row",wrapf(playerPal.get_shader_param("row")+delta*5,playerPal.get_shader_param("palRows")-4,playerPal.get_shader_param("palRows")))
				CHARACTERS.KNUCKLES:
					playerPal.set_shader_param("row",wrapf(playerPal.get_shader_param("row")+delta*5,playerPal.get_shader_param("palRows")-9,playerPal.get_shader_param("palRows")))
			# check if ring count is greater then 0
			# deactivate if stage cleared
			if rings > 0 and Global.stageClearPhase == 0:
				rings -= delta
			else:
				# Deactivate super
				super = false
				supTime = 0
				rings = round(rings)
				if character == CHARACTERS.SONIC:
					sprite.texture = normalSprite
				switch_physics()
				
		if (supTime <= 0):
			if (shield != SHIELDS.NONE):
				shieldSprite.visible = true
			$InvincibilityBarrier.visible = false
			if Global.currentTheme == 0:
				Global.music.play()
				Global.effectTheme.stop()
	else:
	# Deactivate super
		if playerControl != 0:
			playerPal.set_shader_param("row",clamp(playerPal.get_shader_param("row")-delta*10,0,playerPal.get_shader_param("palRows")-3))
	
	if (shoeTime > 0):
		shoeTime -= delta
		if (shoeTime <= 0):
			switch_physics()
			if Global.currentTheme == 1:
				Global.music.play()
				Global.effectTheme.stop()
	
	# Invulnerability timer
	if (invTime > 0 and currentState != STATES.HIT and currentState != STATES.DIE):
		visible = !visible
		invTime -= delta*60
		if (invTime <= 0):
			invTime = 0
			visible = true
	if (ringDisTime > 0):
		ringDisTime -= delta

	# Rings 1up
	if rings >= ring1upCounter:
		ring1upCounter += 100
		# award 1up
		Global.life.play()
		Global.lives += 1
		Global.effectTheme.volume_db = -100
		Global.music.volume_db = -100

	#Rotating stars
	if ($InvincibilityBarrier.visible):
		var stars = $InvincibilityBarrier.get_children()
		for i in stars:
			i.position = i.position.rotated(deg2rad(360*delta*4))
		if (fmod(Global.globalTimer,0.1)+delta > 0.1):
			var star = RotatingParticle.instance()
			var starPart = star.get_node("GenericParticle")
			star.global_position = global_position
			starPart.direction = direction
			get_parent().add_child(star)
			var options = ["StarSingle","StarSinglePat2","default"]
			starPart.play(options[round(randf()*2)])
			starPart.frame = rand_range(0,2)
			starPart.velocity = velocity

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
		"climb":
			animator.playback_speed = -movement.y/(40.0*(1+int(super)))
		_:
			animator.playback_speed = 1
	
	if animator.current_animation != "":
		lastActiveAnimation = animator.current_animation
		
	# Time over
	if Global.levelTime >= Global.maxTime:
		kill()
	
	# Water timer
	if water and shield != SHIELDS.BUBBLE:
		if airTimer > 0:
			if playerControl == 1:
				if stepify(airTimer,airWarning) != stepify(airTimer-delta,airWarning) and airTimer > panicTime:
					sfx[24].play()
			# Count down timer
			if airTimer <= panicTime and stepify(airTimer,1.8) != stepify(airTimer-delta,1.8):
				if round(airTimer/1.8)-2 >= 0:
					var count = CountDown.instance()
					get_parent().add_child(count)
					count.countTime = clamp(round(airTimer/1.8)-2,0,5)
					count.global_position = global_position+Vector2(8*direction,0)
			airTimer -= delta
		elif currentState != STATES.DIE: # Drown (kill checks if air timer is greater then 0)
			$BubbleTimer.start(0.1)
			kill()
	else:
		airTimer = defaultAirTime
	
	# drowning theme related
	if playerControl == 1:
		if !Global.drowning.playing and airTimer <= panicTime and airTimer > 0:
			Global.drowning.play()
		elif Global.drowning.playing and airTimer > panicTime or airTimer <= 0:
			Global.drowning.stop()
	
	# partner control timer for player 2
	if partnerControlTime > 0:
		partnerControlTime -= delta
	
	# Set player inputs
	set_inputs()

func _physics_process(delta):
	
	# Attacking is for rolling type animations
	var attacking = false
	# lists to check through for attack animations
	var currentAnimChecks = [
	"roll","dropDash","spinDash","glide"
	]
	var lastActiveAnimCheck = [
	"glide","glideSlide"
	]
	# if any animations match up turn on attacking flag
	for i in currentAnimChecks:
		if animator.current_animation == i:
			attacking = true
	
	for i in lastActiveAnimCheck:
		if lastActiveAnimation == i:
			attacking = true
	
	# physics sets
	# collid with solids if not rolling layer
	set_collision_mask_bit(15,!attacking)
	# collid with solids if not knuckles layer
	set_collision_mask_bit(18,!character == CHARACTERS.KNUCKLES)
	# collid with solids if not rolling or not knuckles layer
	set_collision_mask_bit(20,(character != CHARACTERS.KNUCKLES and !attacking))
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
			camLockTime -= delta
		
		# Boundry handling
		# Pan camera limits to boundries
		
		var viewSize = get_viewport_rect().size
		var viewPos = camera.get_camera_screen_center()
		var scrollSpeed = 4.0*60.0*delta
		
		# Left
		# snap the limit to the edge of the camera if snap out of range
		if limitLeft > viewPos.x-viewSize.x*0.5:
			camera.limit_left = max(viewPos.x-viewSize.x*0.5,camera.limit_left)
		# if limit is inside the camera then pan over
		if abs(camera.limit_left-(viewPos.x-viewSize.x*0.5)) <= viewSize.x*0.5:
			camera.limit_left = move_toward(camera.limit_left,limitLeft,scrollSpeed)
		# else just snap the camera limit since it's not going to move the camera
		else:
			camera.limit_left = limitLeft
		

		# Right
		# snap the limit to the edge of the camera if snap out of range
		if limitRight < viewPos.x+viewSize.x*0.5:
			camera.limit_right = min(viewPos.x+viewSize.x*0.5,camera.limit_right)
		# if limit is inside the camera then pan over
		if abs(camera.limit_right-(viewPos.x+viewSize.x*0.5)) <= viewSize.x*0.5:
			camera.limit_right = move_toward(camera.limit_right,limitRight,scrollSpeed)
		# else just snap the camera limit since it's not going to move the camera
		else:
			camera.limit_right = limitRight

		# Top
		# snap the limit to the edge of the camera if snap out of range
		if limitTop > viewPos.y-viewSize.y*0.5:
			camera.limit_top = max(viewPos.y-viewSize.y*0.5,camera.limit_top)
		# if limit is inside the camera then pan over
		if abs(camera.limit_top-(viewPos.y-viewSize.y*0.5)) <= viewSize.y*0.5:
			camera.limit_top = move_toward(camera.limit_top,limitTop,scrollSpeed)
		# else just snap the camera limit since it's not going to move the camera
		else:
			camera.limit_top = limitTop
		

		# Bottom
		# snap the limit to the edge of the camera if snap out of range
		if limitBottom < viewPos.y+viewSize.y*0.5:
			camera.limit_bottom = min(viewPos.y+viewSize.y*0.5,camera.limit_bottom)
		# if limit is inside the camera then pan over
		if abs(camera.limit_bottom-(viewPos.y+viewSize.y*0.5)) <= viewSize.y*0.5:
			camera.limit_bottom = move_toward(camera.limit_bottom,limitBottom,scrollSpeed)
		# else just snap the camera limit since it's not going to move the camera
		else:
			camera.limit_bottom = limitBottom
		
		# Death at border bottom
		if global_position.y > limitBottom:
			kill()
	
	
	
	
	# Stop movement at borders
	if (global_position.x < limitLeft+cameraMargin or global_position.x > limitRight-cameraMargin):
		movement.x = 0
	# Clamp position
	global_position.x = clamp(global_position.x,limitLeft+cameraMargin,limitRight-cameraMargin)
	
	# Water
	if Global.waterLevel != null and currentState != STATES.DIE:
		# Enter water
		if global_position.y > Global.waterLevel and !water:
			water = true
			switch_physics(true)
			movement.x *= 0.5
			movement.y *= 0.25
			if currentState != STATES.RESPAWN:
				sfx[17].play()
				var splash = Particle.instance()
				splash.behaviour = splash.TYPE.FOLLOW_WATER_SURFACE
				splash.global_position = Vector2(global_position.x,Global.waterLevel-16)
				splash.play("Splash")
				splash.z_index = sprite.z_index+10
				get_parent().add_child(splash)
			
			# Elec shield/Fire shield logic is in HUD script (related to screen flashing)
		# Exit water
		if global_position.y < Global.waterLevel and water:
			water = false
			switch_physics(false)
			movement.y *= 2
			sfx[17].play()
			var splash = Particle.instance()
			splash.behaviour = splash.TYPE.FOLLOW_WATER_SURFACE
			splash.global_position = Vector2(global_position.x,Global.waterLevel-16)
			splash.play("Splash")
			splash.z_index = sprite.z_index+10
			get_parent().add_child(splash)
	
	# Crusher test
	# if in translate mode, ignore crush mechanics
	if !translate:
		var shapeMemory = $HitBox.shape.extents
		
		# Shrink hitbox to test collissions
		$HitBox.shape.extents = Vector2(1,4)
		
		# Do a test move, if a collision was found then kill the player
		var col = move_and_collide(Vector2.ZERO)
		if col and col.collider.get_collision_layer_bit(21):#test_move(global_transform,Vector2.ZERO):
			kill()
		# Reset shape hitbox
		$HitBox.shape.extents = shapeMemory

# Input buttons
func set_inputs():
	# player control inputs
	if playerControl == 0 or playerControl == 2:
		if partnerControlTime <= 0 and playerControl == 2:
			playerControl = 0
		
		for i in inputActions.size():
			var player2Active = false
			# 0 and 1 in inputActions are arrays
			if i <= 1:
				if Input.is_action_pressed(inputActions[i][0]) or Input.is_action_pressed(inputActions[i][1]):
					player2Active = true
			# rest are inputs
			elif Input.is_action_pressed(inputActions[i]):
				player2Active = true
			if player2Active:
				# if none of the button checks fail, give the player control
				playerControl = 2
				partnerControlTime = DEFAULT_PLAYER2_CONTROL_TIME
		
	
	if playerControl > 0:
		inputs[INPUTS.ACTION] = (int(Input.is_action_pressed(inputActions[INPUTS.ACTION]))*2)-int(Input.is_action_just_pressed(inputActions[INPUTS.ACTION]))
		inputs[INPUTS.ACTION3] =  (int(Input.is_action_pressed(inputActions[INPUTS.ACTION3]))*2)-int(Input.is_action_just_pressed(inputActions[INPUTS.ACTION3]))
	
	if (playerControl > 0 and horizontalLockTimer <= 0):
		inputs[INPUTS.XINPUT] = -int(Input.is_action_pressed(inputActions[INPUTS.XINPUT][0]))+int(Input.is_action_pressed(inputActions[INPUTS.XINPUT][1]))
		inputs[INPUTS.YINPUT] = -int(Input.is_action_pressed(inputActions[INPUTS.YINPUT][0]))+int(Input.is_action_pressed(inputActions[INPUTS.YINPUT][1]))
	

func set_state(newState, forceMask = Vector2.ZERO):
	
	$HitBox.position = hitBoxOffset.normal
	
	if currentState != newState:
		var lastState = currentState
		currentState = newState
		if stateList[lastState].has_method("state_exit"):
			stateList[lastState].state_exit()
		
		if stateList[newState].has_method("state_activated"):
			stateList[newState].state_activated()
	
	for i in stateList:
		i.set_process(i == stateList[newState])
		i.set_physics_process(i == stateList[newState])
		i.set_process_input(i == stateList[newState])
	
	var forcePoseChange = Vector2.ZERO
	
	if (forceMask == Vector2.ZERO):
		match(newState):
			STATES.JUMP, STATES.ROLL:
				# adjust y position
				forcePoseChange = ((currentHitbox.ROLL-$HitBox.shape.extents)*Vector2.UP).rotated(rotation)
				
				# change hitbox size
				$HitBox.shape.extents = currentHitbox.ROLL
			STATES.SPINDASH:
				# change hitbox size
				$HitBox.shape.extents = currentHitbox.CROUCH
				
			_:
				# adjust y position
				forcePoseChange = ((currentHitbox.NORMAL-$HitBox.shape.extents)*Vector2.UP).rotated(rotation)
				
				# change hitbox size
				$HitBox.shape.extents = currentHitbox.NORMAL
	else:
		# adjust y position
		forcePoseChange = ((forceMask-$HitBox.shape.extents)*Vector2.UP).rotated(rotation)
		# change hitbox size
		$HitBox.shape.extents = forceMask
	
	position += forcePoseChange
	
	sprite.get_node("DashDust").visible = false

# sets the hitbox mask shape, referenced in other states
func set_hitbox(mask = Vector2.ZERO, forcePoseChange = false):
	# adjust position if on floor or force pose change
	if ground or forcePoseChange:
		position += ((mask-$HitBox.shape.extents)*Vector2.UP).rotated(rotation)
	
	$HitBox.shape.extents = mask

# set shields
func set_shield(setShieldID):
	magnetShape.disabled = true
	# verify not in water and shield compatible
	if water and (setShieldID == SHIELDS.FIRE or setShieldID == SHIELDS.ELEC):
		return false
	
	shield = setShieldID
	shieldSprite.visible = !super
	match (shield):
		SHIELDS.NORMAL:
			shieldSprite.play("Default")
			sfx[5].play()
		SHIELDS.ELEC:
			shieldSprite.play("Elec")
			sfx[10].play()
			magnetShape.disabled = false
		SHIELDS.FIRE:
			shieldSprite.play("Fire")
			sfx[11].play()
		SHIELDS.BUBBLE:
			shieldSprite.play("Bubble")
			sfx[12].play()
		_: # disable
			shieldSprite.visible = false



# see Global for damage types, 0 = none, 1 = Fire, 2 = Elec, 3 = Water
func hit_player(damagePoint = global_position, damageType = 0, soundID = 6):
	if damageType != 0 and shield == damageType+1:
		return false
	if (currentState != STATES.HIT and invTime <= 0 and supTime <= 0 and (shieldSprite.get_node("InstaShieldHitbox/HitBox").disabled or character != CHARACTERS.SONIC)):
		movement.x = sign(global_position.x-damagePoint.x)*2*60
		movement.y = -4*60
		if (movement.x == 0):
			movement.x = 2*60

		disconect_from_floor()
		#ground = false
		set_state(STATES.HIT)
		invTime = 120
		# Ring loss
		if (shield == SHIELDS.NONE and rings > 0 and playerControl == 1):
			sfx[9].play()
			ringDisTime = 64/60 # ignore rings for 64 frames
			var ringCount = 0
			var ringAngle = 101.25
			var ringAlt = false
			var ringSpeed = 4
			while (ringCount < min(rings,32)):
				# Create ring
				var ring = Ring.instance()
				ring.global_position = global_position
				ring.scattered = true
				ring.velocity.y = -sin(deg2rad(ringAngle))*ringSpeed*60
				ring.velocity.x = cos(deg2rad(ringAngle))*ringSpeed*60

				if (ringAlt):
					ring.velocity.x *= -1
					ringAngle += 22.5
				ringAlt = !ringAlt
				ringCount += 1
				# if we're on the second circle, decrease the speed
				if (ringCount == 16):
					ringSpeed = 2
					ringAngle = 101.25 # Reset angle
				get_parent().add_child(ring)
			rings = 0
		elif shield == SHIELDS.NONE and playerControl == 1:
			kill()
		else:
			sfx[soundID].play()
		# Disable Shield
		set_shield(SHIELDS.NONE)
		return true
	return false

func get_ring():
	if playerControl == 1:
		rings += 1
		sfx[7+ringChannel].play()
		sfx[7].play()
		ringChannel = int(!ringChannel)
		
	elif partner != null:
		partner.get_ring()
	
func kill():
	if currentState != STATES.DIE:
		disconect_from_floor()
		super = false
		supTime = 0
		shoeTime = 0
		if Global.currentTheme == 1:
			#Global.music.stream_paused = false
			Global.music.play()
			Global.effectTheme.stop()
		collision_layer = 0
		collision_mask = 0
		z_index = 100
		if airTimer > 0:
			movement = Vector2(0,-7*60)
			animator.play("die")
			sfx[6].play()
		else:
			if playerControl == 1:
				Global.music.stop()
				Global.effectTheme.stop()
				print("A")
			movement = Vector2(0,0)
			animator.play("drown")
			sfx[25].play()
		set_state(STATES.DIE,currentHitbox.NORMAL)
		
		if playerControl == 1:
			Global.main.sceneCanPause = false # stop the ability to pause

func respawn():
	airTimer = 1
	collision_layer = 0
	collision_mask = 0
	z_index = defaultZIndex
	respawnTime = RESPAWN_DEFAULT_TIME
	movement = Vector2.ZERO
	water = false
	global_position = partner.global_position+Vector2(0,-get_viewport_rect().size.y)
	limitLeft = partner.limitLeft
	limitRight = partner.limitRight
	limitTop = partner.limitTop
	limitBottom = partner.limitBottom
	get_node("TailsCarryBox/HitBox").disabled = true
	set_state(STATES.RESPAWN)


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
	var calcAngle = wrapf(rad2deg(angle)-rad2deg(gravityAngle),0,360)
	
	# check not shallow
	if (calcAngle >= 22.5 and calcAngle <= 337.5 and abs(movement.x) < movement.y):
		# check half steep
		if (calcAngle < 45 or calcAngle > 315):
			movement.x = movement.y*0.5*sign(sin(angle-gravityAngle))
		# else do full steep
		else:
			movement.x = movement.y*sign(sin(angle-gravityAngle))


# clean animation
func _on_PlayerAnimation_animation_started(_anim_name):
	if (sprite != null):
		sprite.flip_v = false
		sprite.offset = defaultSpriteOffset
		if animator.playback_speed < 0:
			animator.playback_speed = abs(animator.playback_speed)
		elif animator.playback_speed == 0:
			animator.playback_speed = 1
		animator.advance(0)

# return the physics id variable, see physicsList array for reference
func determine_physics():
	# get physics from character
	match (character):
		CHARACTERS.SONIC:
			if super:
				return 4 # Super Sonic
			elif shoeTime > 0:
				return 3 # Shoes
			return 0 # Sonic
		CHARACTERS.TAILS:
			if super:
				return 5 # Super Tails
			elif shoeTime > 0:
				return 3 # Shoes
			return 1 # Tails
		CHARACTERS.KNUCKLES:
			if super:
				return 6 # Super Knuckles
			elif shoeTime > 0:
				return 7 # Shoes
			return 2 # Knuckles
	
	return -1

func switch_physics(isWater = water):
	var physicsID = determine_physics()
	var getList = physicsList[max(0,physicsID)]
	if isWater:
		getList = waterPhysicsList[max(0,physicsID)]
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



func _on_SparkleTimer_timeout():
	if super and abs(groundSpeed) >= top:
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
	match(character):
		CHARACTERS.TAILS:
			match($HitBox.shape.extents):
				currentHitbox.ROLL:
					camAdjust = Vector2(0,-1)
				_:
					camAdjust = Vector2.ZERO
		_: # default
			match($HitBox.shape.extents):
				currentHitbox.ROLL:
					camAdjust = Vector2(0,-5)
				_:
					camAdjust = Vector2.ZERO

	# Camera lock
	# remove round() if you are not making a pixel perfect game
	var getPos = (global_position+Vector2(0,camLookOff)+camAdjust).round()
	if camLockTime <= 0 and (forceMove or camera.global_position.distance_to(getPos) <= 16):
		# clamped speed camera
		camera.global_position.x = move_toward(camera.global_position.x,getPos.x,16*60*get_physics_process_delta_time())
		camera.global_position.y = move_toward(camera.global_position.y,getPos.y,16*60*get_physics_process_delta_time())
		# clamp to region
		camera.global_position.x = clamp(camera.global_position.x,limitLeft,limitRight)
		camera.global_position.y = clamp(camera.global_position.y,limitTop,limitBottom)
		#camera.global_position = camera.global_position.move_toward(getPos,16*60*get_physics_process_delta_time())
		# uncomment below for immediate camera
		#camera.global_position = getPos

func lock_camera(time = 1):
	camLockTime = max(time,camLockTime)
	

func snap_camera_to_limits():
	camera.limit_left = max(limitLeft,Global.hardBorderLeft)
	camera.limit_right = min(limitRight,Global.hardBorderRight)
	camera.limit_top = max(limitTop,Global.hardBorderTop)
	camera.limit_bottom = min(limitBottom,Global.hardBorderBottom)

# Water bubble timer
func _on_BubbleTimer_timeout():
	if water:
		# Generate Bubble
		var bub = Bubble.instance()
		bub.z_index = z_index+3
		if airTimer > 0:
			bub.global_position = global_position+Vector2(8*direction,0)
			$BubbleTimer.start(max(randf()*3,0.5))
		elif movement.y < 250:
			bub.global_position = global_position+Vector2(0,-8)
			# pick either 0 or 1 for the bubble type (cosmetic)
			bub.bubbleType = int(round(randf()))
			$BubbleTimer.start(0.1)
		else:
			bub.queue_free()
			$BubbleTimer.start(max(randf()*3,0.5))
		get_parent().add_child(bub)

# player actions

# player movements
func action_move(delta):
	if (inputs[INPUTS.XINPUT] != 0):
		if (movement.x*inputs[INPUTS.XINPUT] < top):
			if (sign(movement.x) == inputs[INPUTS.XINPUT]):
				if (abs(movement.x) < top):
					movement.x = clamp(movement.x+acc/GlobalFunctions.div_by_delta(delta)*inputs[INPUTS.XINPUT],-top,top)
			else:
				# reverse direction
				movement.x += dec/GlobalFunctions.div_by_delta(delta)*inputs[INPUTS.XINPUT]
				# implament weird turning quirk
				if (sign(movement.x) != sign(movement.x-dec/GlobalFunctions.div_by_delta(delta)*inputs[INPUTS.XINPUT])):
					movement.x = 0.5*60*sign(movement.x)
	else:
		if (movement.x != 0):
			# check that decreasing movement won't go too far
			if (sign(movement.x - (frc/GlobalFunctions.div_by_delta(delta))*sign(movement.x)) == sign(movement.x)):
				movement.x -= (frc/GlobalFunctions.div_by_delta(delta))*sign(movement.x)
			else:
				movement.x -= movement.x

func action_jump(animation = "roll", airJumpControl = true):
	animator.play(animation)
	animator.advance(0)
	movement.y = -jmp
	sfx[0].play()
	airControl = airJumpControl
	cameraDragLerp = 1
	disconect_from_floor()
	set_state(STATES.JUMP)

func emit_enemy_bounce():
	emit_signal("enemy_bounced")
