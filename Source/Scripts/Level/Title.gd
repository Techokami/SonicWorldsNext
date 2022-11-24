extends Node2D

export var music = preload("res://Audio/Soundtrack/9. SWD_TitleScreen.ogg")
export var speed = 0
export (PackedScene) var nextScene = load("res://Scene/Presentation/CharacterSelect.tscn")
var titleEnd = false

func _ready():
	Global.music.stream = music
	Global.music.play()

func _process(delta):
	# animate cogs
	$BackCog.rotate(delta*speed)
	$BigCog.rotate(-delta*2*speed)
	$BigCog/CogCircle.rotate(delta*2*speed)
	$Sonic/Cog.rotate(-delta*1.5*speed)
	

func _input(event):
	# end title on start press
	if event.is_action_pressed("gm_pause") and !titleEnd:
		titleEnd = true
		if Global.music.get_playback_position() < 14.0:
			Global.music.seek(14.0)
		Global.main.change_scene(nextScene,"FadeOut","FadeOut","SetSub",1)
		$Celebrations.emitting = true
