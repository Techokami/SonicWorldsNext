extends Node2D

export var music = preload("res://Audio/Soundtrack/6. SWD_TLZa1.ogg")
export (PackedScene) var nextZone = load("res://Scene/Zones/BaseZone.tscn")

export (int, "Bird", "Squirrel", "Rabbit", "Chicken", "Penguin", "Seal", "Pig", "Eagle", "Mouse", "Monkey", "Turtle", "Bear")var animal1 = 0
export (int, "Bird", "Squirrel", "Rabbit", "Chicken", "Penguin", "Seal", "Pig", "Eagle", "Mouse", "Monkey", "Turtle", "Bear")var animal2 = 1

export var setDefaultLeft = true
export var defaultLeftBoundry  = -100000000
export var setDefaultTop = true
export var defaultTopBoundry  = -100000000

export var setDefaultRight = true
export var defaultRightBoundry = 100000000
export var setDefaultBottom = true
export var defaultBottomBoundry = 100000000

var wasLoaded = false

func _ready():
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

	if music != null:
		Global.music.stream = music
		Global.music.play()
		Global.music.stream_paused = false
	else:
		Global.music.stop()
		Global.music.stream = null
	
	if nextZone != null:
		Global.nextZone = nextZone
	Global.main.sceneCanPause = true
	
	Global.animals = [animal1,animal2]
	
	wasLoaded = true
