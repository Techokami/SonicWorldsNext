extends Node

@onready var sceneLoader = $SceneLoader
@onready var music = $Music

func _ready():
	Global.main = self
	switchScene(load("res://scenes/Title.tscn"))
	#switchScene(load("res://scenes/GreenHillAct1.tscn"))


func switchScene(newScene,fadeOutAnim = "",fadeInAnim = "",outSpeed = 1,inSpeed = 1):
	
	$UI/ColorAnimations.speed_scale = outSpeed
	if $UI/ColorAnimations.has_animation(fadeOutAnim):
		$UI/ColorAnimations.play(fadeOutAnim)
		await $UI/ColorAnimations.animation_finished
	# clear current scene
	for i in sceneLoader.get_children():
		i.queue_free()
	# instance and load new scene
	var scene = newScene.instantiate()
	sceneLoader.add_child(scene)
	
	# Fade in
	$UI/ColorAnimations.speed_scale = inSpeed
	if $UI/ColorAnimations.has_animation(fadeInAnim):
		$UI/ColorAnimations.play_backwards(fadeInAnim)
		await $UI/ColorAnimations.animation_finished
	else:
		$UI/ColorAnimations.play("RESET")
	$UI/ColorAnimations.speed_scale = 1
