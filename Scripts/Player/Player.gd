## The PlayerChar class is our main player controller.
class_name PlayerChar extends PhysicsObject

## Enumerator of the various hitbox types
enum HITBOXES { NORMAL, ROLL, CROUCH, GLIDE, HORIZONTAL, NOCHANGE }

var active_physics = preload("res://Scripts/Player/PlayerAvatars/PlayerPhysics/StandardNormal.tres")

# TODO move this to the Spindash state
var spindashPower = 0.0
# TODO Isn't this already in the peelout state?
var peelOutCharge = 0.0
# TODO Consider moving this to the jump state
var abilityUsed = false
# TODO Consider moving this the Air/Jump states
var bounceReaction = 0 # for bubble shield

var invTime = 0
var supTime = 0
var isSuper = false
var shoeTime = 0
var ringDisTime = 0 # ring collecting disable timer

# water settings
var water = false
var defaultAirTime = 30 # 30 seconds
var panicTime = 12 # start count down at 12 seconds
var airWarning = 5 # time between air meter sound
var airTimer = defaultAirTime

# force roll variables
var forceRoll = 0 # each force roll object the player is in, this increments.
var forceDirection = 0

# collision related values
var pushingWall = 0

# Used to keep track of a combo level for calculating points when killing enemies and other
# similar actions
var enemyCounter = 0

# Which character is this player controlling?
var character: Global.CHARACTERS = Global.CHARACTERS.SONIC

var Ring = preload("res://Entities/Items/Ring.tscn")
var ringChannel = 0

var Particle = preload("res://Entities/Misc/GenericParticle.tscn")
var CountDown = preload("res://Entities/Misc/CountDownTimer.tscn")
var RotatingParticle = preload("res://Entities/Misc/RotatingParticle.tscn")

# ================

var horizontalLockTimer = 0
var spriteRotation = 0
var airControl = true

# States
enum STATES {NORMAL, AIR, JUMP, ROLL, SPINDASH, PEELOUT, PATHFOLLOW, HIT, DIE, CORKSCREW, 
SUPER, FLY, RESPAWN, GIMMICK, GLIDE, CHARACTERACTION}
var current_state = STATES.AIR
@onready var hitBoxOffset = {normal = $HitBox.position, crouch = $HitBox.position}
@onready var defaultHitBoxPos = $HitBox.position
var crouchBox = null

## Shield enumerator - keep COUNT as the last entry since it is used to know how
## many options there are.
enum SHIELDS {NONE, NORMAL, FIRE, ELEC, BUBBLE, COUNT}
var shield = SHIELDS.NONE
@onready var magnetShape = $RingMagnet/CollisionShape2D
@onready var shieldSprite: AnimatedSprite2D = $Shields
var reflective = false # used for reflecting projectiles

# State array
@onready var state_list = $States.get_children()

# Animation related
# XXX This will all be deprecated soon. Use get_avatar() to get at all the sprite/animation stuff instead.
@onready var _animator: PlayerCharAnimationPlayer = $Sonic/PlayerAnimation 
@onready var superAnimator = $Sonic/SuperPalette
@onready var sprite = $Sonic/Sprite2D
@onready var player_avatar: PlayerAvatar = $Sonic
var centerReference = null # center reference is a center reference point used for hitboxes and shields (the sprite node need a node called "CenterReference" for this to work)
var lastActiveAnimation = ""
var defaultSpriteOffset = Vector2.ZERO

# TODO - Convert this to a Camera2D subclass that holds all the relevant data instead of keeping it
#        with the player.
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

# screen scroll locking as the camera scrolls
var rachetScrollLeft = false
var rachetScrollRight = false
var rachetScrollTop = false
var rachetScrollBottom = false

var rotatableSprites = ["walk", "run", "peelOut", "hammerSwing"]
var direction = scale.x

# Ground speed is mostly used for timing and animations, there isn't any functionality to it.
var groundSpeed = 0

enum INPUTS {XINPUT, YINPUT, ACTION, ACTION2, ACTION3, SUPER, PAUSE}
# Input control, 0 = 0ff, 1 = pressed, 2 = held
# (for held it's best to use inputs[INPUTS.ACTION] > 0)
# XInput and YInput are directions and are either -1, 0 or 1.
var inputs = [0,0,0,0,0,0,0,0]
const INPUTACTIONS_P1 = [["gm_left","gm_right"],["gm_up","gm_down"],"gm_action","gm_action2","gm_action3","gm_super","gm_pause"]
const INPUTACTIONS_P2 = [["gm_left_P2","gm_right_P2"],["gm_up_P2","gm_down_P2"],"gm_action_P2","gm_action2_P2","gm_action3_P2","gm_super_P2","gm_pause_P2"]
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
@onready var defaultLayer = collision_layer
@onready var defaultMask = collision_mask
@onready var defaultZIndex = z_index

# Input Memory is a circular queue backed by a 2D array. Player 2 draws from memoryPosition + 1
# while the player inserts at memoryPosition. In effect, Player 2 is always drawing control memory
# from the memory that was written memoryPosition frames ago.
#
# The first indice of the inputMemory queue is the queue position.
# The Second indice refers to the particular input.
#
# Example: inputMemory[5][INPUT.XINPUT] is controller memory that was written while memoryPosition was equal to 5
# and the specific input tracked is INPUT.XINPUT
#
# Note: Unless you are specifically writing something that manipulates player 2's AI control, you
# should never need to worry about any of these details.
var inputMemory = []
# Used to track current position in the queue - this is where the player inserts into memory
#
# XXX TODO; Note that since we're doing this on process and not physics_process, the speed that we
# exhaust the memoryPosition is going to vary based on monitor refresh rate. Once we migrate to
# Godot 4, we can check the refresh rate of the user's monitor and adjust the buffer size
# accordingly.
var memoryPosition = 0
const INPUT_MEMORY_LENGTH = 20

var Player = load("res://Entities/MainObjects/Player.tscn")

# Arrays, in order of Global.CHARACTERS
static var playeravatars = [
	preload("res://Entities/PlayerAvatars/Sonic.tscn"),
	preload("res://Entities/PlayerAvatars/Sonic.tscn"),
	preload("res://Entities/PlayerAvatars/Tails.tscn"),
	preload("res://Entities/PlayerAvatars/Knuckles.tscn"),
	preload("res://Entities/PlayerAvatars/Amy.tscn"),
	preload("res://Entities/PlayerAvatars/Shadow.tscn"),
]

# Get sfx list
@onready var sfx = $SFX.get_children()

# Player values
var rings = 0
var ring1upCounter = 100

# How far in can the player can be towards the screen edge before they're limit_length
var cameraMargin = 16

# Gimmick related
## @deprecated
var poleGrabID = null # Please don't use this anymore, use active_gimmick instead

## The current gimmick the player is interacting with if that player is interacting with one.
## Otherwise NULL. If this gimmick is set, the player will call a secondary process function and a
## pleyer hysics process function as part of that player's process/phsyics process functions.
var active_gimmick : ConnectableGimmick = null

## Dictionary of Variables related to the active gimmick (you probably don't need to proactively
## clear these)
var gimmick_variables = {}

## A list of up to max_locked_gimmicks gimmick references that are used to tell that gimmick not to
## bind to the player until they are reset. As a general rule, you should set up a timer to reset them
## but you can also reset them menually. Gimmicks are responsible for checking their own locking logic.
## Note: Gimmicks must be programmed to check this list in order for it to do anything!
var locked_gimmicks: Array[ConnectableGimmick] = [null, null, null]

## Constrain the size of the locked gimmicks list to ensure that checking for the presence of a specific
## locked gimmick within the list remains performant. Make sure this size is in sync with the locked_gimmicks declaration.
var max_locked_gimmicks: int = 3

## Tracks the position that the lost lockedGimmick as added to the locked_gimmicks list.
var locked_gimmicks_index: int = 0


# Enemy related
signal enemy_bounced
signal player_bounced(player: PlayerChar)


func _ready():
	super()

	Global.players.append(self)
	var _con = connect("connectFloor",Callable(self,"_land_floor"))
	_con = connect("connectCeiling",Callable(self,"_touch_ceiling"))
	
	# Camera settings
	get_parent().call_deferred("add_child", (camera))
	camera.enabled = (playerControl == 1)
	var viewSize = get_viewport_rect().size
	camera.drag_left_margin =   camDist.x/viewSize.x
	camera.drag_right_margin =  camDist.x/viewSize.x
	camera.drag_top_margin =    camDist.y/viewSize.y
	camera.drag_bottom_margin = camDist.y/viewSize.y
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	_con = connect("positionChanged",Callable(self,"_on_position_changed"))
	camera.global_position = global_position
	
	# verify that we are player 1
	if playerControl == 1:
		# input memory
		for _i in range(INPUT_MEMORY_LENGTH):
			inputMemory.append(inputs.duplicate(true))
		# Partner (if player character 2 isn't none)
		if Global.PlayerChar2 != Global.CHARACTERS.NONE:
			partner = Player.instantiate()
			partner.playerControl = 0
			partner.z_index = z_index-1
			get_parent().call_deferred("add_child", (partner))
			partner.global_position = global_position+Vector2(-24,0)
			partner.partner = self
			partner.character = Global.PlayerChar2
			partner.inputActions = INPUTACTIONS_P2
		
		# set my character - Uh... isn't this going to work on player 2 as well?
		character = Global.PlayerChar1
	
	# Checkpoints
	await get_tree().process_frame
	for i in Global.checkPoints:
		if Global.currentCheckPoint == i.checkPointID:
			global_position = i.global_position+Vector2(0,8)
			camera.global_position = i.global_position+Vector2(0,8)
			Global.levelTime = Global.checkPointTime
		else:
			Global.levelTime = 0
	
	# Character settings
	var avatar = playeravatars[0]
	if character != Global.CHARACTERS.NONE:
		avatar = playeravatars[character]
	
	player_avatar.name = "OldSprite"
	var new_avatar: PlayerAvatar = avatar.instantiate()
	add_child(new_avatar)
	
	sprite = new_avatar.get_node("Sprite2D")
	_animator = new_avatar.get_node("PlayerAnimation")
	_animator.animation_finished.connect(handle_animation_finished)
	superAnimator = new_avatar.get_node_or_null("SuperPalette")
	player_avatar.queue_free()
	new_avatar.register_state_modifications(self)
	player_avatar = new_avatar
	
	if character == Global.CHARACTERS.AMY:
		maxCharGroundHeight = 12 # adjust Amy's height distance to prevent clipping off floors
	
	# run switch physics to ensure character specific physics
	switch_physics()
	
	# Set hitbox
	$HitBox.shape.size = player_avatar.get_hitbox(HITBOXES.NORMAL)
	
	# connect _animator
	_animator.connect("animation_started",Callable(self,"_on_PlayerAnimation_animation_started"))
	defaultSpriteOffset = sprite.offset
	
	# set secondary hitboxes
	crouchBox = player_avatar.get_node_or_null("CrouchBox")
	if crouchBox != null:
		crouchBox.get_parent().remove_child(crouchBox)
		add_child(crouchBox)
		crouchBox.disabled = true
		hitBoxOffset.crouch = crouchBox.position
	
	# add center reference node
	centerReference = player_avatar.get_node_or_null("CenterReference")
	# hide reference
	if centerReference:
		centerReference.visible = false
	
	# reset camera limits
	limitLeft = Global.hardBorderLeft
	limitRight = Global.hardBorderRight
	limitTop = Global.hardBorderTop
	limitBottom = Global.hardBorderBottom
	_snap_camera_to_limits()
	
	# set partner sounds to share players (prevents sound overlap)
	if playerControl == 0:
		partner.sfx = sfx


## Returns the input for a button as a numerical value
##
## @param event
## @param action Which action binding are you checking for
## @retval 0 not pressed
## @retval 1 pressed
## @retval 2 held (best to do > 0 when checking input)
## @retval -1 released
func calculate_input(event, action = "gm_action"):
	return int(event.is_action(action) or event.is_action_pressed(action))-int(event.is_action_released(action))


func _process(delta):
	# Player 1 input settings and partner AI
	if playerControl == 1:
		# Input memory - write the player's input to the inputMemory queue at the current queue position
		for i in range(inputs.size()):
			inputMemory[memoryPosition][i] = inputs[i]

		# Go ahead and advance the position to the one we wrote INPUT_MEMORY_LENGTH frames ago... it's the
		# next one we want to read anyway *and* the next one we want to write after that.
		memoryPosition = (memoryPosition + 1) % INPUT_MEMORY_LENGTH

		# Partner ai logic
		if partner != null:
			# Check if partner panic
			if partnerPanic <= 0:
				if partner.playerControl == 0:
					for i in partner.inputs.size():
						# Copy the frame of input from the oldest written portion of the inputMemory
						# Array into the partner's input for the current frame
						partner.inputs[i] = inputMemory[memoryPosition][i]
				
				#TODO: This current implimentation is better than what we had before,
				#but it's still a little clunky. Will clean up this clode block later. - Ikey Ilex
				
				# x distance difference check, try to go to the partner
				if (partner.inputs[INPUTS.XINPUT] == 0 and partner.inputs[INPUTS.YINPUT] == 0
					or global_position.distance_to(partner.global_position) > 48 and round(movement.x/300) == 0
					) and abs(global_position.x-partner.global_position.x) >= 32:
					partner.inputs[INPUTS.XINPUT] = sign(global_position.x - partner.global_position.x)
				
				#If more than 64 pixels away on X, override AI control to come back.
				if abs(global_position.x-partner.global_position.x) <= 64:
					var testPos = round(global_position.x + (0-direction))
					if sign((partner.global_position.x - testPos)*direction) > 0:
						partner.inputs[INPUTS.XINPUT] = sign(0-direction)
				
				# Jump if pushing a wall, slower then half speed, on a flat surface and is either normal or jumping
				var top_speed = active_physics.top_speed
				# TODO This condition is a code smell
				if ((partner.current_state == STATES.NORMAL or
				    partner.current_state == STATES.JUMP) and
					abs(partner.movement.x) < top_speed/2.0 and
					snap_angle(partner.angle) == 0 or
					(partner.pushingWall != 0 and pushingWall == 0)):
					# check partners position, only jump ever 0.25 seconds (prevent jump spam)
					if global_position.y+32 < partner.global_position.y and partner.inputs[INPUTS.ACTION] == 0 and partner.ground and ground and (fmod(Global.globalTimer+delta,0.25) < fmod(Global.globalTimer,0.25)):
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
					# press action every 0.3 ticks
					if fmod(partnerPanic+delta,0.3) < fmod(partnerPanic,0.3):
						partner.inputs[INPUTS.ACTION] = 1
					else:
						partner.inputs[INPUTS.ACTION] = 0

			# Panic
			# if partner is locked, and stopped then do a spindash
			# panic for 128 frames before letting go of spindash
			if partner.horizontalLockTimer > 0 and partner.current_state == STATES.NORMAL and global_position.distance_to(partner.global_position) > 48:
				partnerPanic = 128/60.0

	# respawn mechanics
	else:
		if $ScreenCheck.is_on_screen():
			respawnTime = RESPAWN_DEFAULT_TIME
		else:
			if respawnTime > 0:
				respawnTime -= delta
			else:
				respawn()
				
			
	
	# Sprite2D rotation handling
	if (ground):
		spriteRotation = rad_to_deg(angle)+rad_to_deg(gravityAngle)+90
	else:
		if (spriteRotation+90 >= 180):
			spriteRotation = max(90,spriteRotation-(168.75*delta))
		else:
			spriteRotation = min(360,spriteRotation+(168.75*delta))
	
	# set the sprite to match the sprite rotation variable if it's in the rotatable Sprites list
	if (rotatableSprites.has(_animator.current_animation)):
		if (Global.smoothRotation):
			sprite.rotation = deg_to_rad(spriteRotation-90)-rotation-gravityAngle
		else:
			# check if player rotation is greater then 45 degrees or current angle doesn't match the gravity's angle or not on the floor
			if abs(spriteRotation-90) >= 32 or rotation != gravityAngle or !ground:
				sprite.rotation = deg_to_rad(snapped(spriteRotation,45)-90)-rotation-gravityAngle
			else:
				sprite.rotation = -rotation-gravityAngle
	else:
		sprite.rotation = -rotation+gravityAngle

	player_avatar.global_position = global_position.round()

	# Sprite center offset referencing for shields
	if centerReference != null:
		shieldSprite.global_position = centerReference.global_position

	if (horizontalLockTimer > 0 and ground):
		horizontalLockTimer -= delta

	# super / invincibility handling
	if (supTime > 0):
		if !isSuper:
			supTime -= delta
		else:
			$InvincibilityBarrier.visible = false
			# Animate Palette
			# check if ring count is greater then 0
			# deactivate if stage cleared
			if rings > 0 and !Global.is_in_any_stage_clear_phase():
				rings -= delta
			else:
				# Deactivate super
				supTime = 0
				rings = round(rings)
				player_avatar.end_super()
		
		if (supTime <= 0):
			if (shield != SHIELDS.NONE):
				shieldSprite.visible = true
			$InvincibilityBarrier.visible = false
			# turn off super palette and physics (if super)
			if is_instance_valid(superAnimator) and isSuper:
				isSuper = false
				superAnimator.play("PowerDown")
				switch_physics()
			MusicController.stop_music_theme(MusicController.MusicTheme.INVINCIBLE)
	
	if (shoeTime > 0):
		shoeTime -= delta
		if (shoeTime <= 0):
			switch_physics()
			MusicController.stop_music_theme(MusicController.MusicTheme.SPEED_UP)
	
	# Invulnerability timer
	if (invTime > 0 and current_state != STATES.HIT and current_state != STATES.DIE):
		var mod_inv_time = (int(invTime)) % 2
		if mod_inv_time == 0:
			visible = false
		else:
			visible = true
		invTime -= delta*60
		if (invTime <= 0):
			invTime = 0
			visible = true
	if (ringDisTime > 0) and current_state != STATES.HIT:
		ringDisTime -= delta

	#Rotating stars
	if ($InvincibilityBarrier.visible):
		var stars = $InvincibilityBarrier.get_children()
		for i in stars:
			i.position = i.position.rotated(deg_to_rad(360*delta*4))
			i.visible = visible

		if (fmod(Global.globalTimer,0.1)+delta > 0.1) and visible:
			var star = RotatingParticle.instantiate()
			var starPart = star.get_node("GenericParticle")
			star.global_position = global_position
			starPart.getTarget = self
			starPart.direction = -direction
			get_parent().add_child(star)
			var options = ["StarSingle","StarSinglePat2","default"]
			starPart.play(options[round(randf()*2)])
			starPart.frame = randf_range(0,2)
			starPart.velocity = velocity
			starPart.position = stars[0].global_position-global_position

	# Animator
	if current_state != STATES.PEELOUT:
		_handle_animation_speed()
	else:
		_handle_animation_speed(peelOutCharge)
	
	if _animator.current_animation != "":
		lastActiveAnimation = _animator.current_animation
		
	# Time over
	if Global.levelTime >= Global.maxTime:
		kill()
		
	# Water timer
	if water and shield != SHIELDS.BUBBLE:
		if airTimer > 0:
			if playerControl == 1:
				if snapped(airTimer,airWarning) != snapped(airTimer-delta,airWarning) and airTimer > panicTime:
					sfx[24].play()
			# Count down timer
			if airTimer <= panicTime and snapped(airTimer,1.8) != snapped(airTimer-delta,1.8):
				if round(airTimer/1.8)-2 >= 0:
					var count = CountDown.instantiate()
					get_parent().add_child(count)
					count.countTime = clamp(round(airTimer/1.8)-2,0,5)
					count.global_position = global_position+Vector2(8*direction,0)
			airTimer -= delta
		elif current_state != STATES.DIE: # Drown (kill checks if air timer is greater then 0)
			$BubbleTimer.start(0.1)
			kill()
	else:
		airTimer = defaultAirTime
	
	# drowning theme related
	if playerControl == 1:
		if !MusicController.is_music_theme_playing(MusicController.MusicTheme.DROWNING) and \
		   airTimer <= panicTime and airTimer > 0:
			MusicController.play_music_theme(MusicController.MusicTheme.DROWNING)
		elif MusicController.is_music_theme_playing(MusicController.MusicTheme.DROWNING) and \
			 airTimer > panicTime or airTimer <= 0:
			MusicController.stop_music_theme(MusicController.MusicTheme.DROWNING)
	
	# partner control timer for player 2
	if partnerControlTime > 0:
		partnerControlTime -= delta
	
	# Set player inputs
	_set_inputs()
	
	if (active_gimmick != null):
		active_gimmick.player_process(self, delta)
		
	state_list[current_state].state_process_entry(delta)


func _physics_process(delta):
	super(delta)
	
	if ground and forceRoll > 0:
		if (movement*Vector2(1,0)).is_equal_approx(Vector2.ZERO):
			movement.x = 2*sign(-1+(forceDirection*2))*60.0
		if current_state != STATES.ROLL:
			set_state(STATES.ROLL)
			_animator.play("roll")
			sfx[1].play()
			
	
	# TODO - DW's Note - I feel like we should either let the state control whether the
	#        player is 'attacking' rather than animation checks.
	
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
	if _animator.current_animation in currentAnimChecks:
			attacking = true
	
	
	if lastActiveAnimation in lastActiveAnimCheck:
		attacking = true
	
	# physics sets
	# collide with solids if not rolling layer
	set_collision_mask_value(16,!attacking)
	# collide with solids if not knuckles layer
	set_collision_mask_value(19,!character == Global.CHARACTERS.KNUCKLES)
	# collide with solids if not rolling or not knuckles layer
	set_collision_mask_value(21,(character != Global.CHARACTERS.KNUCKLES and !attacking))
	# damage mask bit
	set_collision_layer_value(20,attacking)
	# water surface running
	set_collision_mask_value(23,ground and abs(groundSpeed) >= 7*60 and !water)
	
	if (ground):
		groundSpeed = movement.x
		
	# wall detection
	if horizontalSensor.is_colliding() or is_on_wall():
		var getDir = sign(horizontalSensor.target_position.x)
		if is_on_wall():
			getDir = -sign(get_wall_normal().x)
		
		# give pushingWall a buffer otherwise this just switches on and off
		pushingWall = getDir*2
		if sign(movement.x) == sign(horizontalSensor.target_position.x):
			movement.x = 0
		# disable pushing wall
		if inputs[INPUTS.XINPUT] != sign(pushingWall):
			pushingWall = 0
		
	elif pushingWall != 0:
		# count down pushingwall
		pushingWall -= sign(pushingWall)
	
	
	# TODO - DW's note - if we create a Camera2D subclass, we can move all this code over there.
	# Camera settings
	if (camera != null):
		
		# Lerp camera scroll based on if on floor
		var playerOffset = ((abs(global_position.y-camera.get_target_position().y)*2)/camDist.y)
		var scrollSpeed = 4.0*60.0*delta
		
		cameraDragLerp = max(int(!ground),min(cameraDragLerp,playerOffset)-6*delta)
		
		# Looking/Lag
		# camLookDist is the distance, 0 is up, 1 is down
		camLookAmount = clamp(camLookAmount,-1,1)
		camLookOff = lerp(0,camLookDist[0],min(0,-camLookAmount))+lerp(0,camLookDist[1],min(0,camLookAmount))
		
		
		if camLookAmount != 0:
			var tmpScrollSpeed = sign(camLookAmount)*delta*2
			if sign(camLookAmount - tmpScrollSpeed) == sign(camLookAmount):
				camLookAmount -= sign(camLookAmount)*delta*2
			else:
				camLookAmount = 0
		
		# Camera Lock
		
		if camLockTime > 0:
			camLockTime -= delta
		
		# Boundry handling
		# Pan camera limits to boundries
		
		var viewSize = get_viewport_rect().size
		var viewPos = camera.get_screen_center_position()
		
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
	
	
	# center offsets (only moves hitbox if the centers moved)
	if centerReference != null:
		if centerReference.position != Vector2.ZERO:
			# change to center offset if the center position is different
			$HitBox.position = centerReference.position
	
	# Water
	if Global.waterLevel != null and current_state != STATES.DIE:
		# Enter water
		if global_position.y > Global.waterLevel and !water:
			water = true
			switch_physics()
			movement.x *= 0.5
			movement.y *= 0.25
			if current_state != STATES.RESPAWN and movement.y != 0:
				sfx[17].play()
				var splash = Particle.instantiate()
				splash.behaviour = splash.TYPE.FOLLOW_WATER_SURFACE
				splash.global_position = Vector2(global_position.x,Global.waterLevel-16)
				splash.play("Splash")
				splash.z_index = sprite.z_index+10
				get_parent().add_child(splash)
			
			# Elec shield/Fire shield logic is in HUD script (related to screen flashing)
		# Exit water
		if global_position.y < Global.waterLevel and water:
			water = false
			switch_physics()
			movement.y *= 2
			sfx[17].play()
			var splash = Particle.instantiate()
			splash.behaviour = splash.TYPE.FOLLOW_WATER_SURFACE
			splash.global_position = Vector2(global_position.x,Global.waterLevel-16)
			splash.play("Splash")
			splash.z_index = sprite.z_index+10
			get_parent().add_child(splash)
	
	# We don't check for crushing if the player is in an invulnerable state (note that invulernable means immune to crushing/death by falling)
	if !state_list[current_state].get_invulnerability():
		var crushSensorLeft = $CrushSensorLeft
		var crushSensorRight = $CrushSensorRight
		var crushSensorUp = $CrushSensorUp
		var crushSensorDown = $CrushSensorDown
		
		crushSensorLeft.position.x = -($HitBox.shape.size.x/2 - 1)
		crushSensorRight.position.x = ($HitBox.shape.size.x/2 - 1)
		crushSensorUp.position.y = -($HitBox.shape.size.y/2 -1)
		# note that the bottom crush sensor actually goes *below* the feet so that it can contact the floor
		crushSensorDown.position.y = ($HitBox.shape.size.y/2 +1)
		
		# crusher deaths NOTE: the allowTranslate and visibility is used for stuff like the sky sanctuary teleporters, visibility check is for stuff like the carnival night barrels
		if (crushSensorLeft.get_overlapping_areas() + crushSensorLeft.get_overlapping_bodies()).size() > 0 and \
			(crushSensorRight.get_overlapping_areas() + crushSensorRight.get_overlapping_bodies()).size() > 0 and (!allowTranslate or visible):
			kill()

		if (crushSensorUp.get_overlapping_areas() + crushSensorUp.get_overlapping_bodies()).size() > 0 and \
			(crushSensorDown.get_overlapping_areas() + crushSensorDown.get_overlapping_bodies()).size() > 0 and (!allowTranslate or visible):
			kill()
			
	if (active_gimmick != null):
		active_gimmick.player_physics_process(self, delta)

	state_list[current_state].state_physics_process(delta)


# Reads the controller state for the player
func _set_inputs():
	# player control inputs
	# check if ai or player 2
	if playerControl == 0 or playerControl == 2:
		# player 2 active time check, if below 0 return to ai state
		if partnerControlTime <= 0 and playerControl == 2:
			playerControl = 0
		
		# player 2 control active check
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
		inputs[INPUTS.ACTION2] = (int(Input.is_action_pressed(inputActions[INPUTS.ACTION2]))*2)-int(Input.is_action_just_pressed(inputActions[INPUTS.ACTION2]))
		inputs[INPUTS.ACTION3] =  (int(Input.is_action_pressed(inputActions[INPUTS.ACTION3]))*2)-int(Input.is_action_just_pressed(inputActions[INPUTS.ACTION3]))
		inputs[INPUTS.SUPER] =  (int(Input.is_action_pressed(inputActions[INPUTS.SUPER]))*2)-int(Input.is_action_just_pressed(inputActions[INPUTS.SUPER]))
		inputs[INPUTS.XINPUT] = -int(Input.is_action_pressed(inputActions[INPUTS.XINPUT][0]))+int(Input.is_action_pressed(inputActions[INPUTS.XINPUT][1]))
		inputs[INPUTS.YINPUT] = -int(Input.is_action_pressed(inputActions[INPUTS.YINPUT][0]))+int(Input.is_action_pressed(inputActions[INPUTS.YINPUT][1]))


# Controller scan functions -- so you don't have to dig into the inputs to check controller state
## Returns true if any of the three action buttons were just pressed this frame
func any_action_pressed():
	if (inputs[INPUTS.ACTION] == 1
	or inputs[INPUTS.ACTION2] == 1 or
	inputs[INPUTS.ACTION3] == 1):
		return true
	return false


## Returns true if any of the action buttons have been held for more than one frame
func any_action_held():
	if inputs[INPUTS.ACTION] == 2:
		return true
	if inputs[INPUTS.ACTION2] == 2:
		return true
	if inputs[INPUTS.ACTION3] == 2:
		return true
	return false

## Returns true if any of the three action buttons are currently held/pressed
func any_action_held_or_pressed():
	if inputs[INPUTS.ACTION] > 0:
		return true
	if inputs[INPUTS.ACTION2] > 0:
		return true
	if inputs[INPUTS.ACTION3] > 0:
		return true
	return false


## This probably seems really niche, but it's useful to prevent
## Certain jump actions from instantly turning into player specific double
## jump abilities.
func convert_pressed_action_btns_to_held():
	if inputs[INPUTS.ACTION] == 1:
		inputs[INPUTS.ACTION] = 2
	if inputs[INPUTS.ACTION2] == 1:
		inputs[INPUTS.ACTION2] = 2
	if inputs[INPUTS.ACTION2] == 1:
		inputs[INPUTS.ACTION2] = 2


## Check the y input of the player's controller
func get_y_input():
	return inputs[INPUTS.YINPUT]


## Check the if the player is holding up on their controller
## Note: a press and a hold are the same thing for directions -- no effort is made to track the
## difference for these.
func is_up_held():
	return inputs[INPUTS.YINPUT] < 0


## Check the if the player is holding dow on their controller	
## Note: a press and a hold are the same thing for directions -- no effort is made to track the
## difference for these.
func is_down_held():
	return inputs[INPUTS.YINPUT] > 0


## Check the x input of the player's controller
func get_x_input():
	return inputs[INPUTS.XINPUT]


## Check the if the player is holding left on their controller
## Note: a press and a hold are the same thing for directions -- no effort is made to track the
## difference for these.
func is_left_held():
	return inputs[INPUTS.XINPUT] < 0


## Check the if the player is holding right on their controller	
## Note: a press and a hold are the same thing for directions -- no effort is made to track the
## difference for these.
func is_right_held():
	return inputs[INPUTS.XINPUT] > 0


## Hits the player. This usually causes loss of shield, loss of rings, or
## death.
## @param damagePoint  A position vector that can be included to indicate where the hit came from
##                     this affects knockback of the player, but only in the sense that if the hit
##                     comes from the right the player will be knocked back left
##                     and if the hit comes from the left, the player will be knocked back right.
## @param damageType   Defines the hit as belonging to an element. Elemental hits will be ignored if
##                     the player being hit has a shield that would block that element.
## @param soundID      If set, changes which of the player sounds is used for the hit. Note that the
##                     alternate hit sound is only played if ring loss wouldn't be played instead.
##                     The main use for this is when the player interacts with spikes in which case
##                     the spike sound is used instead. To know which sounds are available, check the
##                     SFX object in the Player.tscn -- streamers in there are indexed in order of their
##                     position in the list starting from 0.
func hit_player(damagePoint:Vector2 = global_position, damageType: Global.HAZARDS = Global.HAZARDS.NORMAL, soundID:int = 6):
	if damageType != 0 and shield == damageType+1:
		return false
	if (current_state != STATES.HIT and invTime <= 0 and supTime <= 0 and (shieldSprite.get_node("InstaShieldHitbox/HitBox").disabled or character != Global.CHARACTERS.SONIC)):
		movement.x = sign(global_position.x-damagePoint.x)*2*60
		movement.y = -4*60
		if (movement.x == 0):
			movement.x = 2*60
		# check for water
		if water:
			movement = movement*0.5

		force_detach()
		disconnect_from_floor()
		set_state(STATES.HIT)
		invTime = 120 # Ivulnerable for 2 seconds. Starts counting *after* landing.
		# Ring loss
		if (shield == SHIELDS.NONE and rings > 0 and is_independent()):
			sfx[9].play()
			ringDisTime = 30.0/60.0 # ignore rings for 30 frames after landing
			var ringCount = 0
			var ringAngle = 101.25
			var ringAlt = false
			var ringSpeed = 4
			while (ringCount < min(rings,32)):
				# Create ring
				var ring = Ring.instantiate()
				ring.global_position = global_position
				ring.scattered = true
				ring.velocity.y = -sin(deg_to_rad(ringAngle))*ringSpeed*60
				ring.velocity.x = cos(deg_to_rad(ringAngle))*ringSpeed*60

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
		elif shield == SHIELDS.NONE and is_independent():
			kill()
		else:
			sfx[soundID].play()
		# Disable Shield
		set_shield(SHIELDS.NONE)
		return true
	return false


## Determines whether the player should be treated like player 1 for the purpose of gimmicks and
## similar things. This is determined by a combination of whether or not they actually *are* player
## 1 and if the game mode is in one of the more multiplayer centric modes.
func is_independent()->bool:
	# First player is always indepdent
	if Global.get_first_player() == self:
		return true

	# Players other than the first are indepdendent in non-standard mutliplayer modes
	if Global.get_multimode() != Global.MULTIMODE.NORMAL:
		return true
	
	return false


## Gives the player a ring by default, overridable to any requested number.
##
## @param num_rings - one by default. This may be negative to take away rings,
##                    but doing so won't make rings to negative or kill the
##                    player
## @param play_sound - optional parameter. If set to false, the ring acquisition
##                     sound will not be played. Particularly useful if you
##                     either want to play a different sound like with the loss
##                     state in a slot machine or just no sound at all like with
##                     the gassed status effect that toxomister gives you.
func give_ring(num_rings: int = 1, play_sound: bool = true) -> void:
	# We should come back to this after we decouple player from playerchar
	# so that we can let a player 2 character get rings if the game is in versus
	# mode
	if !is_independent():
		return Global.get_first_player().give_ring(num_rings, play_sound)

	rings += num_rings
	
	# If this is one of those things that takes rings, don't play the ring acquisition sound, don't
	# bother checking for 
	if (num_rings < 1):
		# Also floor the rings at 0... don't let it go negative, this isn't Knuckles Chaotix.
		if rings < 0:
			rings = 0
		return

	if play_sound:
		sfx[7+ringChannel].play()
		sfx[7].play()
		ringChannel = int(!ringChannel)
	
	# Rings 1up
	if rings >= ring1upCounter:
		ring1upCounter += 100
		# award 1up
		MusicController.play_music_theme(MusicController.MusicTheme._1UP)
		Global.lives += 1


## Resets the player's air timer to the default air time value
func reset_air()->void:
	airTimer = defaultAirTime


## Murders the player instantly
func kill():
	# Already dying
	if current_state == STATES.DIE:
		return
		
	disconnect_from_floor()
	supTime = 0
	shoeTime = 0
	allowTranslate = true
	# turn off super palette and physics (if super)
	if isSuper:
		player_avatar.end_super()
		isSuper = false
		
	# stop special music
	if playerControl == 1 and MusicController.is_music_theme_with_priority_playing(MusicController.PriorityLevel.EFFECT_THEME):
		MusicController.stop_music_theme_with_priority(MusicController.PriorityLevel.EFFECT_THEME)
			
	# If Player 1 dies and a partner exists, initiate respawn flying from current position.
	if playerControl == 1 and partner:
		var savedPos = partner.global_position
		partner.respawn()
		partner.global_position = savedPos
			
	collision_layer = 0
	collision_mask = 0
	z_index = 100
	if airTimer > 0:
		water = false
		switch_physics()
		movement = Vector2(0,-7*60)
		_animator.play("die")
		sfx[6].play()
	else:
		if playerControl == 1:
			MusicController.stop_music_theme(MusicController.MusicTheme.LEVEL_THEME)
			MusicController.stop_music_theme_with_priority(MusicController.PriorityLevel.EFFECT_THEME)
		movement = Vector2(0,0)
		_animator.play("drown")
		sfx[25].play()

	set_state(STATES.DIE,player_avatar.get_hitbox(HITBOXES.NORMAL))
		
	#if playerControl == 1:
		#Global.main.sceneCanPause = false # stop the ability to pause


## Makes a partner character re-enter the scene
## TODO: Make this compatible with partners other than Tails
func respawn() -> void:
	if partner == null:
		return
	
	# cancel function if partner is dead or ai controlled
	if partner.current_state == STATES.DIE || partner.playerControl != 1:
		return
		
	airTimer = 1
	collision_layer = 0
	collision_mask = 0
	z_index = defaultZIndex
	respawnTime = RESPAWN_DEFAULT_TIME
	movement = Vector2.ZERO
	water = false
	# update physics (prevents player having water physics on respawn)
	switch_physics()
	global_position = partner.global_position+Vector2(0,-get_viewport_rect().size.y)
	limitLeft = partner.limitLeft
	limitRight = partner.limitRight
	limitTop = partner.limitTop
	limitBottom = partner.limitBottom
		
	set_state(STATES.RESPAWN)


## Gets the character's partner (note that in the current to player setup, each player character is
## the other's partner, so calling get_partner on Sonic in Sonic and Tails mode gets Tails and
## calling it on Tails gets Sonic.
func get_partner() -> PlayerChar:
	return partner


func _touch_ceiling():
	if getVert != null:
		var getAngle = wrapf(-rad_to_deg(getVert.get_collision_normal().angle())-90,0,360)
		if (getAngle > 225 or getAngle < 135):
			angle = getAngle
			rotation = snap_angle(-deg_to_rad(getAngle))
			update_sensors()
			movement = -Vector2(movement.y*sign(sin(deg_to_rad(getAngle))),0)
			ground = true
			return true
	movement.y = 0


func _land_floor():
	
	abilityUsed = false
	# landing movement calculation
	
	# recalculate ground angle
	var calcAngle = wrapf(rad_to_deg(angle)-rad_to_deg(gravityAngle),0,360)
	
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
		sprite.flip_v = false # Won't this make reverse-gravity kind of impossible?
		sprite.offset = defaultSpriteOffset
		if _animator.speed_scale < 0:
			_animator.speed_scale = abs(_animator.speed_scale)
		elif _animator.speed_scale == 0:
			_animator.speed_scale = 1
		# reset the center offset
		if centerReference != null:
			centerReference.position = Vector2.ZERO
		_animator.advance(0)


## Gets the currently active physics table
func get_physics() -> PlayerPhysics:
	return active_physics


## Resets the PlayerChar's physics attributes based on their
## current status.
func switch_physics() -> void:
	active_physics = get_avatar().get_physics(water, isSuper, shoeTime > 0)


func _on_SparkleTimer_timeout() -> void:
	if isSuper and abs(groundSpeed) >= active_physics.top_speed:
		var sparkle = Particle.instantiate()
		sparkle.global_position = global_position
		sparkle.play("Super")
		get_parent().add_child(sparkle)


func _on_position_changed():
	cam_update(true)


## Repositions the player camera per normal camera movement rules
## @param force_move Ignores camera locking mechanics if true
func cam_update(forceMove = false) -> void:
	# Cancel camera movement
	if current_state == STATES.DIE:
		return
		
	# Camera vertical drag
	var viewSize = get_viewport_rect().size
	
	camera.drag_top_margin =    lerp(0.0,float(camDist.y/viewSize.y),float(cameraDragLerp))
	camera.drag_bottom_margin = camera.drag_top_margin
	
	# Extra drag margin for rolling
	match(character):
		Global.CHARACTERS.TAILS:
			if get_state() == STATES.ROLL:
				camAdjust = Vector2(0,-1)
			else:
				camAdjust = Vector2.ZERO
		_: # default
			if get_state() == STATES.ROLL:
				camAdjust = Vector2(0,-5)
			else:
				camAdjust = Vector2.ZERO
	
	# Camera lock
	# remove round() if you are not making a pixel perfect game
	var getPos = (global_position+Vector2(0,camLookOff)+camAdjust).round()
	if camLockTime <= 0 and (forceMove or camera.global_position.distance_to(getPos) <= 16):
		# limit_length speed camera
		camera.global_position.x = move_toward(camera.global_position.x,getPos.x,16*60*get_physics_process_delta_time())
		camera.global_position.y = move_toward(camera.global_position.y,getPos.y,16*60*get_physics_process_delta_time())
		# clamp to region
		camera.global_position.x = clamp(camera.global_position.x,limitLeft,limitRight)
		camera.global_position.y = clamp(camera.global_position.y,limitTop,limitBottom)
		#camera.global_position = camera.global_position.move_toward(getPos,16*60*get_physics_process_delta_time())
		# uncomment below for immediate camera
		#camera.global_position = getPos
	
	# Ratchet camera scrolling (locks the camera behind the player)
	if rachetScrollLeft:
		limitLeft = max(limitLeft,camera.get_screen_center_position().x-viewSize.x/2)
	if rachetScrollRight:
		limitRight = max(limitRight,camera.get_screen_center_position().x+viewSize.x/2)
	
	if rachetScrollTop:
		limitTop = max(limitTop,camera.get_screen_center_position().y-viewSize.y/2)
	if rachetScrollBottom:
		limitBottom = max(limitBottom,camera.get_screen_center_position().y+viewSize.y/2)


## Locks the position of the camera for a while
## @param time how long (in seconds) to lock the camera for
## Note: If the camera is already locked, this function can raise
## the locked time up to time, but it can't go below the current
## remaining lock time.
func lock_camera(time: float = 1.0):
	camLockTime = max(time,camLockTime)


func _snap_camera_to_limits():
	camera.limit_left = max(limitLeft,Global.hardBorderLeft)
	camera.limit_right = min(limitRight,Global.hardBorderRight)
	camera.limit_top = max(limitTop,Global.hardBorderTop)
	camera.limit_bottom = min(limitBottom,Global.hardBorderBottom)


# Water bubble timer
func _on_BubbleTimer_timeout():
	if water:
		# Generate Bubble
		if airTimer > 0:
			Bubble.create_small_bubble(get_parent().get_parent(),global_position+Vector2(8*direction,0),Vector2.ZERO,0.0,z_index+3)
			$BubbleTimer.start(max(randf()*3,0.5))
		elif movement.y < 250:
			Bubble.create_small_or_medium_bubble(get_parent().get_parent(),global_position+Vector2(0,-8),Vector2.ZERO,0.0,z_index+3)
			$BubbleTimer.start(0.1)
		else:
			$BubbleTimer.start(max(randf()*3,0.5))


## Handles player's standard movement based on controller input -- you might call this if you are
## programming either a state or a gimmick that uses the GIMMICK state and don't want to take
## standard directional control away from the player.
func action_move(delta):
	# moving left and right, check if left or right is being pressed
	if inputs[INPUTS.XINPUT] != 0:
		if horizontalLockTimer <= 0: # skip logic if lock timer is around, friction gets skipped too since the original games worked like that
			# check if movement is less then the top speed
			var top_speed = active_physics.top_speed
			if movement.x*inputs[INPUTS.XINPUT] < top_speed:
				# check if the player is pressing the direction they're moving
				if sign(movement.x) == inputs[INPUTS.XINPUT] or sign(movement.x) == 0:
					if abs(movement.x) < top_speed:
						movement.x = move_toward(movement.x,top_speed*inputs[INPUTS.XINPUT],
							active_physics.acceleration / GlobalFunctions.div_by_delta(delta))
				else:
					# reverse direction
					movement.x += active_physics.deceleration/GlobalFunctions.div_by_delta(delta)*inputs[INPUTS.XINPUT]
					# implament weird turning quirk
					if (sign(movement.x) != sign(movement.x-active_physics.deceleration/GlobalFunctions.div_by_delta(delta)*inputs[INPUTS.XINPUT])):
						movement.x = 0.5*60*sign(movement.x)
	else:
		# come to a stop if neither left or right is pressed
		if (movement.x != 0):
			# check that decreasing movement won't go too far
			var friction = active_physics.friction
			if (sign(movement.x - (friction/GlobalFunctions.div_by_delta(delta))*sign(movement.x)) == sign(movement.x)):
				movement.x -= (friction/GlobalFunctions.div_by_delta(delta))*sign(movement.x)
			else:
				movement.x -= movement.x


## Makes the player jump with their standard jump strength
func action_jump(animation = "roll", air_jump_control : bool = true, play_sound : bool = true):
	if forceRoll <= 0: # check to prevent jumping in roll tubes
		_animator.play(animation)
		_animator.advance(0)
		movement.y = -active_physics.jump_strength
		if play_sound:
			sfx[0].play()
		airControl = air_jump_control
		cameraDragLerp = 1
		disconnect_from_floor()
		set_state(STATES.JUMP)


## Restores the player's ability to use double jump action. The player still
## has to be in a state where it is available in the first place to do so.
func reset_double_jump_action() -> void:
	abilityUsed = false


## Makes the player emit the enemy_bounced signal
func emit_enemy_bounce():
	enemy_bounced.emit()


## Makes the player emit the player_bounced signal - only if the player bounces off the ground
## for some reason.
## TODO - does this occur for anything other than bubble shield in the air state?
func emit_player_bounce():
	player_bounced.emit(self)


## Makes the player perform water run actions if applicable. Only really has an impact if
## the player is in contact iwth the water's surface. You invoke this in any action that
## water running is allowed from.
func action_water_run_handle():
	var dash = $WaterSurface
	# check for water (check that collision has the water tag)
	var touchWater = false
	var colCheck = move_and_collide(Vector2.DOWN.rotated(rotation),true)
	if colCheck:
		touchWater = colCheck.get_collider().get_collision_layer_value(23)
	
	# enable dash dust if touching water
	dash.visible = (get_collision_mask_value(23) and touchWater and ground)
	dash.scale.x = sign(movement.x)
	dash.position.y = $HitBox.shape.size.y/2.0

	# play water run sound
	if get_collision_mask_value(23) and touchWater and ground:
		if !sfx[29].playing:
			sfx[29].play()
	else:
		sfx[29].stop()


# TODO Move to PlayerAvatar
func _handle_animation_speed(gSpeed = groundSpeed):
	match(_animator.current_animation):
		"walk", "run", "peelOut":
			if character == Global.CHARACTERS.SHADOW:
				var duration = floor(max(0,12.0-abs(gSpeed/60.0)))
				_animator.speed_scale = (1.0/(duration+1.0))*(60.0/10.0)
			else:
				var duration = floor(max(0,8.0-abs(gSpeed/60.0)))
				_animator.speed_scale = (1.0/(duration+1.0))*(60.0/10.0)
		"roll":
			var duration = floor(max(0,4.0-abs(gSpeed/60.0)))
			_animator.speed_scale = (1.0/(duration+1.0))*(60.0/10.0)
		"push":
			var duration = floor(max(0,8.0-abs(gSpeed/60.0)) * 4)
			_animator.speed_scale = (1.0/(duration+1.0))*(60.0/10.0)
		"spinDash": #animate at 60fps (fps were animated at 0.1 seconds)
			_animator.speed_scale = 60.0/10.0
		"dropDash":
			_animator.speed_scale = 20.0/10.0
		"climb":
			_animator.speed_scale = -movement.y/(40.0*(1.0+float(isSuper)))
		_:
			_animator.speed_scale = 1


# Standard getters and setters -- for future code, please try to avoid direct
# access of player variables. Use getters/setters instead. This aids in easing
# refactoring.
## Gets the current state value of the player
## Note: gets the enum value only, not the actual state object
func get_state()->PlayerChar.STATES:
	return current_state

## Use this variant of get_state when you want to check character actions and not standard states.
func get_state_character_action()->int:
	if current_state != STATES.CHARACTERACTION:
		return -1
	else:
		var action_state_obj = state_list[STATES.CHARACTERACTION]
		return action_state_obj.get_character_action_state_index
		



## Gets a player state object
## I don't recommend using this function, but we have some code in the codebase
## that uses this approach so I'm exposing it anyway. The preferred way to read/
## manipulate a player's state value is usually going to be to add a new function
## to the player that does it for you.
##
## @param for_state - which state you want to get the state object for
## @retval PlayerState object that the for_state value represents
func get_state_object(for_state: PlayerChar.STATES) -> PlayerState:
	return state_list[for_state]


## Sets the player's state while performing normal state change operations
## Always use this to set the player's state. Don't try to change the player's
## state directly.
##
## @param new_state - State player is changing to
## @param force_mask - Vector2 for a mask change. Note that ZERO is the default, but it implies
##                     change. This needs work.
## @param skip_supplements - If this is enabled (and if set_state is called from a supplement, it
##                           should be), we won't run supplements.
## @param new_character_state - Should only be used if setting the state to CHARACTERACTION.
##                              This value is used to set up the CHARACTERACTION state to make it
##                              proxy to the new character action state as well as to engage
##                              enter/exit for the character-specific state and to run supplements
##                              that might affect that state.
func set_state(new_state: PlayerChar.STATES,
		force_mask:Vector2 = Vector2.ZERO,
		skip_supplements:bool = false,
		new_character_state: int = -1):	
	
	var new_state_obj: PlayerState = null
	var old_state_obj: PlayerState = state_list[current_state]
	
	defaultHitBoxPos = hitBoxOffset.normal
	$HitBox.position = defaultHitBoxPos
	
	if new_state == STATES.CHARACTERACTION:
		new_state_obj = player_avatar.get_character_state_object(new_character_state)
		if new_state_obj == null:
			push_error("Attempted to set CHARACTERACTION with invalid new_character_state")
			return
	else:
		new_state_obj = state_list[new_state]
	
	# reset the center offset
	if centerReference != null:
		centerReference.position = Vector2.ZERO

	# Run the state exit supplements unless we were told not to. If we are told to bail, do so.
	if !skip_supplements and old_state_obj.state_exit_entry(new_state, new_character_state) == false:
		return
	
	# Enter the new state. If a supplement tells us to abandon the state change, do so.
	# TODO XXX Coming later
	
	new_state_obj.state_activated()
	
	# If we are using a CharacterAction state, we need to set the proxy to the new character action
	# being proxied now.
	if new_state == STATES.CHARACTERACTION:
		var character_action_state: CharacterActionState = state_list[STATES.CHARACTERACTION]
		character_action_state.set_character_action_state(new_character_state)
	
	current_state = new_state
	
	var forcePoseChange = Vector2.ZERO
	
	if (force_mask == Vector2.ZERO):
		match(new_state):
			STATES.JUMP, STATES.ROLL:
				# adjust y position
				forcePoseChange = ((player_avatar.get_hitbox(HITBOXES.ROLL)-$HitBox.shape.size)*Vector2.UP).rotated(rotation)*0.5
				
				# change hitbox size
				$HitBox.shape.size = player_avatar.get_hitbox(HITBOXES.ROLL)
			STATES.SPINDASH:
				# change hitbox size
				$HitBox.shape.size = player_avatar.get_hitbox(HITBOXES.CROUCH)
				
			_:
				# adjust y position
				forcePoseChange = ((player_avatar.get_hitbox(HITBOXES.NORMAL)-$HitBox.shape.size)*Vector2.UP).rotated(rotation)*0.5
				
				# change hitbox size
				$HitBox.shape.size = player_avatar.get_hitbox(HITBOXES.NORMAL)
	else:
		# adjust y position
		forcePoseChange = ((force_mask-$HitBox.shape.size)*Vector2.UP).rotated(rotation)*0.5
		# change hitbox size
		$HitBox.shape.size = force_mask
	
	position += forcePoseChange
	
	sprite.get_node("DashDust").visible = false


## Shorthand for setting the character state to character action while also providing
## a new_character_state. Generally this is preferable to use over the full form version when
## switching to a character-specific state.
func set_character_action_state(new_character_state: int,
		force_mask:Vector2 = Vector2.ZERO,
		skip_supplements:bool = false,
	):
		set_state(STATES.CHARACTERACTION, force_mask, skip_supplements, new_character_state)


## sets the hitbox mask shape, referenced in other states
## @param size - new hitbox size
## @param force_pose_change normally if the player's hitbox size changes
##        and they are on the ground, the player's hitbox will be repositioned to
##        maintain the same bottom position. Using force_pose_change causes this
##        behavior to be used with this set_hitbox operation even if the player isn't
##        on the ground.
func set_hitbox(size = Vector2.ZERO, force_pose_change = false):
	# adjust position if on floor or force pose change
	if ground or force_pose_change:
		position += ((size-$HitBox.shape.size)*Vector2.UP).rotated(rotation)*0.5
	
	$HitBox.shape.size = size


## Gets the size of the current hitbox
func get_hitbox() -> Vector2:
	return $HitBox.shape.size


## Gets the predefined hitbox dimensions for a predefined hitbox.
## predefined hitboxes are listed in the PlayerChar.HITBOXES enum.
## TODO -> Just get the avatar and use get_hitbox instead.
func get_predefined_hitbox(which: PlayerChar.HITBOXES) -> Vector2:
	return player_avatar.get_hitbox(which)


## sets the hitbox mask shape to one of the predefined shapes.
func set_predefined_hitbox(which: PlayerChar.HITBOXES, force_pose_change: bool = false):
	return set_hitbox(get_predefined_hitbox(which), force_pose_change)


## Sets the player's shield
## @param setShieldID - Which shield the player should get
func set_shield(setShieldID: PlayerChar.SHIELDS) -> void:
	magnetShape.disabled = true
	# verify not in water and shield compatible
	if water and (setShieldID == SHIELDS.FIRE or setShieldID == SHIELDS.ELEC):
		return
	
	shield = setShieldID
	# make shield visible if not super and the invincibility barrier isn't going
	shieldSprite.visible = !isSuper and !$InvincibilityBarrier.visible
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


## Gets the value of the player's current shield. The value will be one of the
## values of the SHIELDS enumerator for the player.
func get_shield() -> PlayerChar.SHIELDS:
	return self.shield
	

## Returns the current PlayerAvatar for the player. You should use this to get
## to character-specific properties and the animator.
func get_avatar() -> PlayerAvatar:
	return self.player_avatar


## Available directions for the player to use when using set_direction
enum DIRECTIONS {LEFT, RIGHT} # I'd wager there is already something more appropriate


## Sets the direction of the player's sprite and direction value
func set_direction(new_direction: PlayerChar.DIRECTIONS) -> void:
	if new_direction == DIRECTIONS.LEFT:
		direction = -1.0
		sprite.flip_h = true
		return
	direction = 1.0
	sprite.flip_h = false


## Gets the player's direction using the PlayerChar.DIRECTIONS enum
func get_direction() -> PlayerChar.DIRECTIONS:
	if direction < 0:
		return DIRECTIONS.LEFT
	else:
		return DIRECTIONS.RIGHT


## Gets the players direction in a way that is useful for calculations
## @retval -1.0 if left
## @retval 1.0 if right
func get_direction_multiplier() -> float:
	return direction


## Gets the player's ground speed
func get_ground_speed() -> float:
	return groundSpeed


## Sets the player's ground speed
func set_ground_speed(new_ground_speed: float) -> void:
	self.groundSpeed = new_ground_speed


## Gets whether or not the player is in water
func is_in_water() -> bool:
	return self.water


## Sets the player's horizontal lock timer
## Note that the horizontal lock timer being above zero will temporarily prevent
## the player's left/right controls from have an impact.
func set_horizontal_lock_timer(lock_time: float) -> void:
	self.horizontalLockTimer = lock_time


## Sets whether or not the player currently has air control
func set_air_control(control: bool) -> void:
	self.airControl = control


# Player Gimmick Interaction
#
# Up until recently, we've been letting gimmicks store their own per-player
# state and they perform their own on-player processes as part of their own
# process function. Rather than doing that, I think it's going to become
# useful to let the player object be responsible for kicking those kinds of
# actions off while the gimmick process functions focus more on the motion and
# actions of the gimmick itself.
#
# ConnectableGimmick must be extended for the gimmick in question to use the set_active_gimmick
# functionality. Setting gimmick variables on the other hand can be done regardless of whether or
# not the player is on a ConnectableGimmick.
#
# Be aware that not all gimmicks should require explicit attachment to the player. Whether or not
# one does depends primarily on whether or not the gimmick needs to maintain its own state on each
# player. Gimmicks that can function without continually tracking some kind of per-player state
# should continue to do so without using these functions.
#
# Also be aware that failing to disconnect a gimmick when you should is going to cause lots of
# problems with other gimmick interactions.

## Binds the player to the requested gimmick
## @param gimmick gimmick to bind the player to
## @param allowSwap enable to make the new gimmick execute its on force detach callback and to
##        allow the new gimmick to replace one that is already attached.
## @retval true if gimmick was able to be connected
## @retval false otherwise
## note: Never returns false if allowSwap is set
func set_active_gimmick(gimmick : ConnectableGimmick, allowSwap : bool=false) -> bool:
	if allowSwap:
		if active_gimmick != null: # if there is already an active gimmick, we need to run that
								  # gimmicks player forced detached callback.
			active_gimmick.player_force_detach_callback(self)
		
		active_gimmick = gimmick
		return true
	
	# when swap is not allowed, we only set it if the player isn't already attached to another gimmick.
	if active_gimmick != null:
		return false
	
	active_gimmick = gimmick
	return true


## Unbinds the gimmick from the player (you could just use null on set_active_gimmick too)
func unset_active_gimmick() -> void:
	active_gimmick = null


## Unbinds the player from its current gimmick, but only after running its force detach
## callback
func force_detach() -> void:
	if active_gimmick == null:
		return

	active_gimmick.player_force_detach_callback(self)
	active_gimmick = null


## Gets the player's currently active gimmick. Might be useful for certain gimmick<->gimmick
## interactions or just for checking if the player is already bound to the gimmick you are checking
## from.
func get_active_gimmick() -> ConnectableGimmick:
	return active_gimmick


## Sets a value in the player's gimmick variable dictionary. Uses a key value pair.
func set_gimmick_var(gimmickVarName: String, gimmickVarValue) -> void:
	gimmick_variables[gimmickVarName] = gimmickVarValue


## Removes a variable from the player's gimmick variable dictionary. Provide a key.
func unset_gimmick_var(gimmickVarName) -> void:
	gimmick_variables.erase(gimmickVarName)


## Gets a value in the player's gimmick variable dictionary. Provide a key.
func get_gimmick_var(gimmickVarName, default: Variant = null):
	return gimmick_variables.get(gimmickVarName, default)


## Removes all currently locked gimmicks from the Player's locked gimmick list.
func clear_locked_gimmicks():
	for i in range(max_locked_gimmicks):
		locked_gimmicks[i] = null
	locked_gimmicks_index = 0


## Locks a gimmick for the player using a timer to unlock it
## @param gimmick - which gimmick should be locked
## @param lock_time - how long should the gimmick be locked in seconds
func timed_gimmick_lock(gimmick: ConnectableGimmick, lock_time: float) -> void:
	var unlock_func = func ():
		clear_single_locked_gimmick(gimmick)
	
	var timer:SceneTreeTimer = get_tree().create_timer(lock_time, false)
	timer.timeout.connect(unlock_func, CONNECT_DEFERRED)
	
	add_locked_gimmick(gimmick)
	pass


## Removes a single locked gimmick from the player's locked gimmick list if
##   present.
func clear_single_locked_gimmick(gimmick : ConnectableGimmick):
	for i in range(max_locked_gimmicks):
		if locked_gimmicks[i] == gimmick:
			locked_gimmicks[i] = null


## Adds a gimmick to the player's locked gimmick list. Useful if you want to
##   prevent a player from interacting or especially re-interacting with a
##   gimmick until that player either lands or you manually clear the locked
##   gimmick list for some reason.
func add_locked_gimmick(gimmick):
	locked_gimmicks[locked_gimmicks_index] = gimmick
	locked_gimmicks_index = (locked_gimmicks_index + 1) % max_locked_gimmicks


## Removes a locked gimmick from the locked gimmicks list for the player
## You can still use this even if the gimmick is no longer in the player's
## locked gimmicks list, it'll just not actually do anything in that case.
func remove_locked_gimmick(gimmick):
	locked_gimmicks.erase(gimmick)


## Checks if the gimmick is locked for the player
func is_gimmick_locked_for_player(gimmick):
	if gimmick in locked_gimmicks:
		return true
	return false


## Invokes the handle_animation_finished callback for the attached gimmick.
func handle_animation_finished(animation):
	if active_gimmick != null:
		active_gimmick.handle_animation_finished(self, animation)
