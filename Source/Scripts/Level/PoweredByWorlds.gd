extends Node2D

# next scene
@export var nextScene = preload("res://Scene/Presentation/Title.tscn")
# already changed is used to check that the powered by isn't already being skipped
var alreadyChanged = false

func _ready():
	# delay so game can start
	await get_tree().create_timer(1).timeout
	# play title if the scene isn't already skipping
	if !alreadyChanged:
		$AnimationPlayer.play("Animation")
		$Emerald.play()
		# wait for the animation to finish
		await $AnimationPlayer.animation_finished
		# do another check, if the scene's not already fading then fade to the next
		if !alreadyChanged:
			alreadyChanged = true
			$Warp.play()
			Global.main.change_scene_to_file(nextScene,"FadeOut","FadeOut","SetSub",1)

func _input(event):
	# check if start gets pressed
	if event.is_action_pressed("gm_pause") and !alreadyChanged:
		alreadyChanged = true # used so that room skipping isn't doubled
		$Warp.play()
		Global.main.change_scene_to_file(nextScene,"FadeOut","FadeOut","SetSub",1)
