class_name Level extends Node2D

@export var music: AudioStream = preload("res://Audio/Soundtrack/6. SWD_TLZa1.ogg")
@export var music_alt: AudioStream = null
@export var nextZone: String = "res://Scene/Zones/BaseZone.tscn"

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

func _ready():
	if setDefaultLeft:
		Global.hardBorderLeft  = defaultLeftBoundry
	if setDefaultRight:
		Global.hardBorderRight = defaultRightBoundry
	if setDefaultTop:
		Global.hardBorderTop    = defaultTopBoundry
	if setDefaultBottom:
		Global.hardBorderBottom  = defaultBottomBoundry
	
	level_reset_data(false)
	Global.set_level(self)

# used for stage starts, also used for returning from special stages
func level_reset_data(playCard = true):
	# music handling
	MusicController.reset_music_themes()
	if music != null:
		MusicController.set_level_music(music, music_alt)
	# set next zone
	Global.nextZone = nextZone
	
	# set pausing to true
	Main.sceneCanPause = true
	# set animals
	Global.animals = [animal1,animal2]
	# if global hud and play card, run hud ready script
	if playCard and is_instance_valid(Global.hud):
		$HUD._ready()
