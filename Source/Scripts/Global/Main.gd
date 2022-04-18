extends Node2D

var lastScene = null

func _ready():
	Global.main = self
	Global.music = $Music
	Global.effectTheme = $EffectTheme
	Global.life = $Life
	Global.reset_values()
	change_scene(load("res://Scene/LevelTest.tscn"))
	

func change_scene(scene = null, fadeOut = "", fadeIn = "", setType = "SetSub"):
	
	$GUI/Fader.play(setType)
	
	if fadeOut != "":
		$GUI/Fader.queue(fadeOut)
		yield($GUI/Fader,"animation_finished")
	
	
	for i in $SceneLoader.get_children():
		i.queue_free()
	# Error prevention
	Global.players = []
		
	if scene == null:
		if lastScene != null:
			$SceneLoader.add_child(lastScene.instance())
	else:
		$SceneLoader.add_child(scene.instance())
		lastScene = scene

	if fadeIn != "":
		$GUI/Fader.play_backwards(fadeIn)
	elif fadeOut != "":
		$GUI/Fader.play("RESET")
