extends Node2D

var weight = 0
var trampolineYVelocity = 0
var trampolineYPosition = 0

export var ringsSprite = preload("res://Graphics/Gimmicks/ICZTrampolineRing.png")
export var ringsPerSide = 3 # How many rings to draw on each side of the platform
export var ringsMargin = 30 # Pixels away from the center of the platform to start drawing rings
export var ringsBetween = 12 # Pixels between each ring drawn
export var weightFactor = 10 # How many pixels the weight of one character moves the pivot point
export var springConstant = 30.0 # No idea on what this should be just yet.
export var dampingFactorWeightless = 0.97 # Lower values make the trampoline slow down more quickly while no players are on it
export var dampingFactorWeighted = 0.98 # Lower values make the trampoline slow down more quickly while one or more players are on it
export var maxVelocity = 700 # The maximum velocity the trampoline can move at once -- acts as a limiter for how high the gimmick can launch you
export var minVelocityForLaunch = 150 # Minimum upward velocity the trampoline must has as it is coming to the pivot in order to launch the player
export var bounceFactor = 1.75 # Multiplier against yVelocity for setting the player's upward launch speed

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
	pass # Replace with function body.

func _process(delta):
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# process_temp(delta)
	var pivot = weight * weightFactor
	var accelerationFactor = (pivot - body.position.y) * springConstant
	
	yVelocity += accelerationFactor * delta
	body.position.y += yVelocity * delta
	# Damping - The trampoline should have a tendency to return to rest
	if weight == 0:
		yVelocity *= dampingFactorWeightless
	else:
		yVelocity *= dampingFactorWeighted
	pass
	
	var passedMidpoint = false
	if (body.position.y < (0.66 * pivot) and yVelocity < -minVelocityForLaunch):
		#print("yVelocity = ", yVelocity)
		passedMidpoint = true
		
	var removedFlag = 0
	
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
		weight = 0
		return

		# if launch is still enabled, we didn't launch, but we need to make do something if a player
	# jumped off the gimmick
	for i in playersOld:
		if not players.has(i):
			var curVel = i.movement.y
			i.movement.y += yVelocity
			if (curVel < 50):
				impart_force(150) # bounce downwards on jump
	pass
	
	# Reset player count, weight and launch to zero for next pass
	weight = 0
	launchEnabled = false
	playersOld = players.duplicate(false)
	players.clear()
	skipGroundCheck = false

func _draw():
	for n in ringsPerSide:
		draw_texture(ringsSprite, Vector2(-ringsMargin - (n * ringsBetween) - ringsSprite.get_width() / 2, 0 - (ringsSprite.get_height() / 2) + (ringsPerSide - n - 1) * body.position.y / (ringsPerSide - 1)))
		draw_texture(ringsSprite, Vector2(ringsMargin + (n * ringsBetween)  - ringsSprite.get_width() / 2, 0 - (ringsSprite.get_height() / 2) + (ringsPerSide - n - 1) * body.position.y / (ringsPerSide - 1)))
