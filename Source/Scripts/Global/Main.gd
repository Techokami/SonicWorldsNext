extends Node2D

func _ready():
	Global.main = self
	Global.music = $Music
	Global.effectTheme = $EffectTheme
	Global.life = $Life
	change_scene(load("res://Scene/LevelTest.tscn"))
	

func change_scene(scene, fadeType = ""):
	$SceneLoader.add_child(scene.instance())
