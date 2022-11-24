extends Node2D

export var music = preload("res://Audio/Soundtrack/6. SWD_TLZa1.ogg")
export (PackedScene) var nextZone = load("res://Scene/Zones/BaseZone.tscn")

export (int, "Bird", "Squirrel", "Rabbit", "Chicken", "Penguin", "Seal", "Pig", "Eagle", "Mouse", "Monkey", "Turtle", "Bear")var animal1 = 0
export (int, "Bird", "Squirrel", "Rabbit", "Chicken", "Penguin", "Seal", "Pig", "Eagle", "Mouse", "Monkey", "Turtle", "Bear")var animal2 = 1

# Boundries
export var setDefaultLeft = true
export var defaultLeftBoundry  = -100000000
export var setDefaultTop = true
export var defaultTopBoundry  = -100000000

export var setDefaultRight = true
export var defaultRightBoundry = 100000000
export var setDefaultBottom = true
export var defaultBottomBoundry = 100000000

# was loaded is used for room loading, this can prevent overwriting global information, see Global.gd for more information on scene loading
var wasLoaded = false

func _ready():
	# skip if scene was loaded
	if wasLoaded:
		return false
	
	if setDefaultLeft:
		Global.hardBorderLeft  = defaultLeftBoundry
	if setDefaultRight:
		Global.hardBorderRight = defaultRightBoundry
	if setDefaultTop:
		Global.hardBorderTop    = defaultTopBoundry
	if setDefaultBottom:
		Global.hardBorderBottom  = defaultBottomBoundry
	
	level_reset_data(false)
	
	wasLoaded = true

# used for stage starts, also used for returning from special stages
func level_reset_data(playCard = true):
	# music handling
	if music != null:
		Global.music.stream = music
		Global.music.play()
		Global.music.stream_paused = false
	else:
		Global.music.stop()
		Global.music.stream = null
	# set next zone
	if nextZone != null:
		Global.nextZone = nextZone
	
	# set pausing to true
	Global.main.sceneCanPause = true
	# set animals
	Global.animals = [animal1,animal2]
	# if global hud and play card, run hud ready script
	if playCard and is_instance_valid(Global.hud):
		$HUD._ready()
