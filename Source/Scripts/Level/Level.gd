extends Node2D

export var music = preload("res://Audio/Soundtrack/6. SWD_TLZa1.ogg")
export (PackedScene) var nextZone = load("res://Scene/Zones/BaseZone.tscn")

func _ready():
	if music != null:
		Global.music.stream = music
		Global.music.play()
	else:
		Global.music.stop()
		Global.music.stream = null
	
	if nextZone != null:
		Global.nextZone = nextZone
	Global.main.sceneCanPause = true
