extends Node2D

@export var music: AudioStream = preload("res://Audio/Soundtrack/9. SWD_TitleScreen.ogg")
@export var speed = 0
@export var nextScene = load("res://Scene/Presentation/CharacterSelect.tscn")
var titleEnd = false

func _ready():
	MusicController.reset_music_themes()
	MusicController.set_level_music(music)

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
		if MusicController.get_music_theme_playback_position(MusicController.MusicTheme.LEVEL_THEME) < 14.0:
			MusicController.seek_music_theme(MusicController.MusicTheme.LEVEL_THEME, 14.0)
		Global.main.change_scene_to_file(nextScene,"FadeOut","FadeOut",1)
		$Celebrations.emitting = true
