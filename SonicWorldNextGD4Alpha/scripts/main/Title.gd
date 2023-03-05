extends Node2D

@export var music = preload("res://Audio/Soundtrack/9. SWD_TitleScreen.ogg")
@export var speed = 0
var titleEnd = false
var startRoom = preload("res://scenes/TileMap.tscn")

func _ready():
	Global.main.music.stream = music
	Global.main.music.play()

func _process(delta):
	$BackCog.rotate(delta*speed)
	$BigCog.rotate(-delta*2*speed)
	$BigCog/CogCircle.rotate(delta*2*speed)
	$Sonic/Cog.rotate(-delta*1.5*speed)
	

func _input(event):
	if event.is_action_pressed("gm_pause") && !titleEnd:
		titleEnd = true
		if Global.main.music.get_playback_position() < 14.0:
			Global.main.music.seek(14.0)
		Global.main.switchScene(startRoom,"FadeBlack","FadeBlack",0.15)
		$Celebrations.emitting = true
