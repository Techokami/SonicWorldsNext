# Ice Cap Zone Trampolines
# by DimensionWarped (February 2023)

@tool
extends "res://Tools/Graphics/AnimatedTextureDrawer.gd"

var weight = 0
var trampolineYVelocity = 0
var trampolineYPosition = 0

# Edit the inherited values to change cosmetic features of the connective rings
# The trampoline inherits the following exported values from AnimatedTextureDrawer
#spriteTexture - Picks the texture used to draw the rings - the spriteTexture should contain frames aligned in a horizontal fashion
#spriteFrameCount - Set this to the number of frames in the sprite Texture2D
#animationMode - if set to pingpong, the animation will play from beginning to end, then end to beginning before looping.
#              - if set to loop, the animation will play from beginning to end and then loop from the beginning
#timePerFrame - how many seconds the animation frame should be played before moving on to the next one. Lower means faster.

# Edit these values to control cosmetic elements about the sprites that get drawn on the side of the trampoline
@export var ringsPerSide = 3 # How many rings to draw on each side of the platform - set to two or less to just get rid of them.
@export var ringsMargin = 30 # Pixels away from the center of the platform to start drawing rings
@export var ringsBetween = 12 # Pixels between each ring drawn

# How the connective rings are positioned
# linear - the rings are placed in a line. Plain, but true to the form of the original. Works best with spaced out rings.
# center_parabolice - the center platform is the apex/trough of the parabola of rings for that classy look
# edge_parabolic - XXX Coming eventually maybe.
enum INTERPOLATION_MODE {linear, center_parabolic}
@export var interpolationMode: INTERPOLATION_MODE = INTERPOLATION_MODE.linear

# Edit this to change the graphic used for the central platform
@export var platformSprite = preload("res://Graphics/Gimmicks/ICZTrampoline.png")
# Edit these values if you change the platform graphic to something of a different size
@export var platformWidth = 22 # how many pixels wide your collider for the platform is. 
@export var platformHeight = 8 # How many pixels tall the platform should be
@export var platformYOffset = 6 # How many vertical pixels to offset the platform

# These are your physical values for the trampoline and affect things
@export var weightFactor = 10 # How many pixels one unit of weight (IE one character) causes the trampoline to sag
@export var springConstant = 30.0 # How rapidly the trampoline snaps back
@export var dampingFactorWeightless = 0.97 # A lower value means the trampoline returns to rest more quickly when not weighted
@export var dampingFactorWeighted = 0.98 # A lower value means the trampoline returns to rest more quickly when weighted
@export var maxVelocity = 700 # The maximum velocity the trampoline can have at any point in time in the downward direction.
@export var minVelocityForLaunch = 150 # If yVelocity of the trampoline exceeds this as the trampoline moves past its rest point (roughly), any players riding it will be launched into the air
@export var bounceFactor = 1.75 # Multiplier for how much of the trampoline's velocity should be imparted to the player when the player is launched (should always be higher than 1)
@export var baseWeight = 0 # If above zero, the trampoline itself will have weight causing it to sag at rest with no one on it.
@export var jumpPushback = 225 # How hard the trampoline should be pushed downward if a riding player jumps off

var trampolineRealY
var launchEnabled

var temp = 0
var yVelocity = 0.0
@onready var body = $TrampolineBody
var passedPivot = true
var players = []
var playersOld = [] # Exists so that we can check the players that exited on the last pass
var skipGroundCheck = false

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	trampolineRealY = body.position.y * 1.0 + baseWeight * weightFactor * 1.0
	pass # Replace with function body.

func _process(_delta):
	if Engine.is_editor_hint():
		$TrampolineBody/TrampolineShape.get_shape().set_size(Vector2(platformWidth, platformHeight / 2))
		$TrampolineBody/TrampolineShape.position.y = -platformYOffset
	super._process(_delta)

func impart_force(velocityChange):
	yVelocity += velocityChange
	yVelocity = clamp(yVelocity, -maxVelocity, maxVelocity)

func set_launch(isLaunchOn):
	launchEnabled = isLaunchOn

func add_player(player):
	players.append(player)
	impart_force(player.movement.y)
	weight += 1
	launchEnabled = true
	player.movement.y = 0
	skipGroundCheck = true

func physics_process_game(delta):
	var pivot = weight * weightFactor
	var accelerationFactor = (pivot - trampolineRealY) * springConstant

	yVelocity += accelerationFactor * delta
	trampolineRealY += yVelocity * delta
	body.position.y = floor(trampolineRealY)
	# Damping - The trampoline should have a tendency to return to rest
	if weight == baseWeight:
		yVelocity *= dampingFactorWeightless
	else:
		yVelocity *= dampingFactorWeighted
	pass
	
	var passedMidpoint = false
	if (trampolineRealY < (0.8 * pivot) and yVelocity < -minVelocityForLaunch):
		passedMidpoint = true

	if (launchEnabled and passedMidpoint):
		for i in players:
			i.set_state(i.STATES.AIR)
			i.movement.y += yVelocity * bounceFactor
			i.animator.play("spring")
			if(abs(i.groundSpeed) >= min(6*60,i.top)):
				i.animator.queue("run")
			else:
				i.animator.queue("walk")

		# Clear everything and return for the next pass
		playersOld.clear()
		players.clear()
		launchEnabled = false
		yVelocity /= 5
		weight = baseWeight
		return

	# if launch is still enabled, we didn't launch, but we need to make do something if a player
	# jumped off the gimmick
	for i in playersOld:
		if not players.has(i):
			var curVel = i.movement.y
			i.movement.y += yVelocity
			if (curVel < 50):
				impart_force(jumpPushback) # bounce downwards on jump
	pass

	# Reset player count, weight and launch to zero for next pass
	weight = baseWeight
	launchEnabled = false
	playersOld = players.duplicate(false)
	players.clear()
	skipGroundCheck = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	physics_process_game(delta)

func draw_tool():
	# Can't draw rings if there aren't enough for the anchors
	if (ringsPerSide < 2):
		return

	var platformOffset = weightFactor * baseWeight
	for n in ringsPerSide:
		var yOffset = 0
		if interpolationMode == INTERPOLATION_MODE.linear:
			yOffset = (ringsPerSide - n - 1) * (platformOffset) / (ringsPerSide - 1)
			pass
		elif interpolationMode == INTERPOLATION_MODE.center_parabolic:
			# vertex is at the platform
			# y = a(x)^2 + k (k = platformOffset)
			yOffset = platformOffset - platformOffset * pow(1.0 * n / (ringsPerSide - 1), 2)
			pass
		else:
			# This shouldn't be possible.
			pass

		draw_at_pos_internal(Vector2(-ringsMargin - (n * ringsBetween), yOffset))
		draw_at_pos_internal(Vector2(ringsMargin + (n * ringsBetween), yOffset))
		
	draw_texture(platformSprite, Vector2(0 - platformSprite.get_width() / 2 , 0 - (platformSprite.get_height() / 2) + platformOffset))

	return

func _draw():
	if Engine.is_editor_hint():
		return draw_tool()

	# Can't draw rings if there aren't enough for the anchors
	if (ringsPerSide < 2):
		return

	var platformOffset = body.position.y
		
	for n in ringsPerSide:
		var yOffset = 0

		if interpolationMode == INTERPOLATION_MODE.linear:
			yOffset = (ringsPerSide - n - 1) * (platformOffset) / (ringsPerSide - 1)
			pass
		elif interpolationMode == INTERPOLATION_MODE.center_parabolic:
			# vertex is at the platform
			# y = a(x)^2 + k (k = platformOffset)
			yOffset = platformOffset - platformOffset * pow(1.0 * n / (ringsPerSide - 1), 2)
			pass
		else:
			# This shouldn't be possible.
			pass

		draw_at_pos_internal(Vector2(-ringsMargin - (n * ringsBetween), yOffset))
		draw_at_pos_internal(Vector2( ringsMargin + (n * ringsBetween), yOffset))
		
	draw_texture(platformSprite, Vector2(0 - platformSprite.get_width() / 2 , 0 - (platformSprite.get_height() / 2) + body.position.y))
