class_name Level extends Node2D

@export var music = preload("res://Audio/Soundtrack/6. SWD_TLZa1.ogg")
@export var nextZone = load("res://Scene/Zones/BaseZone.tscn")

@export var animal1: Animal.ANIMAL_TYPE = Animal.ANIMAL_TYPE.BIRD
@export var animal2: Animal.ANIMAL_TYPE = Animal.ANIMAL_TYPE.SQUIRREL

# Boundries
@export var setDefaultLeft = true
@export var defaultLeftBoundry  = -100000000
@export var setDefaultTop = true
@export var defaultTopBoundry  = -100000000

@export var setDefaultRight = true
@export var defaultRightBoundry = 100000000
@export var setDefaultBottom = true
@export var defaultBottomBoundry = 100000000

# was loaded is used for room loading, this can prevent overwriting global information, see Global.gd for more information on scene loading
var wasLoaded = false

func _ready():
	# debuging
	if !Global.is_main_loaded:
		return false
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
	
	Global.set_level(self)

# used for stage starts, also used for returning from special stages
func level_reset_data(playCard = true):
	# music handling
	Global.bossMusic.stop()
	if Global.music != null:
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
	if Global.main != null:
		Global.main.sceneCanPause = true
	# set animals
	Global.animals = [animal1,animal2]
	# if global hud and play card, run hud ready script
	if playCard and is_instance_valid(Global.hud):
		$HUD._ready()
