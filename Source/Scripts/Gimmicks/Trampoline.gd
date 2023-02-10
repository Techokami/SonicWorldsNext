extends Node2D
tool


var weight = 0
var trampolineYVelocity = 0
var trampolineYPosition = 0

export var platformSprite = preload("res://Graphics/Gimmicks/ICZTrampoline.png")
export var ringsSprite = preload("res://Graphics/Gimmicks/ICZTrampolineRing.png")
export var ringsPerSide = 3 # How many rings to draw on each side of the platform - set to two or less to just get rid of them.
export var ringsMargin = 30 # Pixels away from the center of the platform to start drawing rings
export var ringsBetween = 12 # Pixels between each ring drawn
export var weightFactor = 10 # How many pixels the weight of one character moves the pivot point
export var springConstant = 30.0 # Somewhere between 20-30 seem like the sweet spot for trampolines.
export var dampingFactorWeightless = 0.97 # Lower values make the trampoline slow down more quickly while no players are on it
export var dampingFactorWeighted = 0.98 # Lower values make the trampoline slow down more quickly while one or more players are on it
export var maxVelocity = 700 # The maximum velocity the trampoline can move at once -- acts as a soft limiter for how high the gimmick can launch you
export var minVelocityForLaunch = 150 # Minimum upward velocity the trampoline must has as it is coming to the pivot in order to launch the player. Set it really high to disable launch behavior.
export var bounceFactor = 1.75 # Multiplier against yVelocity for setting the player's upward launch speed
export var baseWeight = 0 # Use this to make the trampoline itself have weight
export var jumpPushback = 225 # This affects how much the trampoline gets pushed if a player jumps off of it.

# How the rings are positioned
# linear - the rings are placed in a line. Plain, but true to the form of the original. Works best with spaced out rings.
# center_parabolice - the center platform is the apex/trough of the parabola of rings for that classy look
# edge_parabolic - Each edge is the apex/trough of a parabola terminating at the platform for that divide by zero look.
enum INTERPOLATION_MODE {linear, center_parabolic, edge_parabolic}
export(INTERPOLATION_MODE) var interpolationMode = INTERPOLATION_MODE.linear

var trampolineRealY
var launchEnabled

var temp = 0
var yVelocity = 0.0
onready var body = $TrampolineBody
var passedPivot = true
var players = []
var playersOld = [] # Exists so that we can check the players that exited on the last pass
var skipGroundCheck = false

# Called when the node enters the scene tree for the first time.
func _ready():
	trampolineRealY = body.position.y * 1.0 + baseWeight * weightFactor * 1.0
	pass # Replace with function body.

func _process(_delta):
	update()
	
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
		var spriteOffset = -(ringsSprite.get_height() / 2)
		if interpolationMode == INTERPOLATION_MODE.linear:
			yOffset = spriteOffset + (ringsPerSide - n - 1) * (platformOffset) / (ringsPerSide - 1)
			pass
		elif interpolationMode == INTERPOLATION_MODE.center_parabolic:
			# vertex is at the platform
			# y = a(x)^2 + k (k = platformOffset + spriteOffset)
			yOffset = spriteOffset + platformOffset - platformOffset * pow(1.0 * n / (ringsPerSide - 1), 2)
			pass
		else:
			# Sorry, it's broken.
			pass
			
		draw_texture(ringsSprite, Vector2(-ringsMargin - (n * ringsBetween) - ringsSprite.get_width() / 2, yOffset))
		draw_texture(ringsSprite, Vector2( ringsMargin + (n * ringsBetween) - ringsSprite.get_width() / 2, yOffset))
		
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
		var spriteOffset = -(ringsSprite.get_height() / 2)
		if interpolationMode == INTERPOLATION_MODE.linear:
			yOffset = spriteOffset + (ringsPerSide - n - 1) * (platformOffset) / (ringsPerSide - 1)
			pass
		elif interpolationMode == INTERPOLATION_MODE.center_parabolic:
			# vertex is at the platform
			# y = a(x)^2 + k (k = platformOffset + spriteOffset)
			yOffset = spriteOffset + platformOffset - platformOffset * pow(1.0 * n / (ringsPerSide - 1), 2)
			pass
		else:
			# Sorry, it's broken.
			pass
			
		draw_texture(ringsSprite, Vector2(-ringsMargin - (n * ringsBetween) - ringsSprite.get_width() / 2, yOffset))
		draw_texture(ringsSprite, Vector2( ringsMargin + (n * ringsBetween) - ringsSprite.get_width() / 2, yOffset))
		
	draw_texture(platformSprite, Vector2(0 - platformSprite.get_width() / 2 , 0 - (platformSprite.get_height() / 2) + body.position.y))
