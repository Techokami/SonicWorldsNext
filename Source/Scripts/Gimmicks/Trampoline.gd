extends Node2D

var weight = 0
var trampolineYVelocity = 0
var trampolineYPosition = 0

export var ringsSprite = preload("res://Graphics/Gimmicks/ICZTrampolineRing.png")
export var ringsPerSide = 3
export var ringsMargin = 30
export var ringsBetween = 12
export var weightFactor = 10
export var springConstant = 20.0 # No idea on what this should be just yet.
export var dampingFactorWeightless = 0.95
export var dampingFactorWeighted = 0.98
export var maxVelocity = 800
export var minVelocityForLaunch = 75
export var bounceFactor = 1.75

var launchEnabled

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var temp = 0
var yVelocity = 0.0
onready var body = $TrampolineBody
var passedPivot = true
var players = []

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
		print("yVelocity = ", yVelocity)
		passedMidpoint = true
	
	if (launchEnabled and passedMidpoint):
		print("launch!")
		for i in players:
			i.set_state(i.STATES.AIR)
			i.movement.y += yVelocity * bounceFactor
			i.animator.play("spring")
			i.animator.queue("walk")
		yVelocity /= 5
		weight = 0
		launchEnabled = false
	
	# Reset player count, weight and launch to zero for next pass
	weight = 0
	launchEnabled = false
	players.clear()

func _draw():
	for n in ringsPerSide:
		draw_texture(ringsSprite, Vector2(-ringsMargin - (n * ringsBetween) - ringsSprite.get_width() / 2, 0 - (ringsSprite.get_height() / 2) + (ringsPerSide - n) * body.position.y / ringsPerSide))
		draw_texture(ringsSprite, Vector2(ringsMargin + (n * ringsBetween)  - ringsSprite.get_width() / 2, 0 - (ringsSprite.get_height() / 2) + (ringsPerSide - n) * body.position.y / ringsPerSide))
