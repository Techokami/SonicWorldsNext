extends Node2D

export var nextScene = preload("res://Scene/Presentation/Title.tscn")
var alreadyChanged = false

func _ready():
	yield(get_tree().create_timer(1),"timeout") #delay so game can start
	# play title
	$AnimationPlayer.play("Animation")
	$Emerald.play()
	yield($AnimationPlayer,"animation_finished")
	if !alreadyChanged:
		alreadyChanged = true
		$Warp.play()
		Global.main.change_scene(nextScene,"FadeOut","FadeOut","SetSub",1)

func _input(event):
	if event.is_action_pressed("gm_pause") and !alreadyChanged:
		alreadyChanged = true
		$Warp.play()
		Global.main.change_scene(nextScene,"FadeOut","FadeOut","SetSub",1)
