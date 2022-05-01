extends "res://Scripts/Player/State.gd"

func _physics_process(delta):
	parent.movement.y += parent.grv/delta;
	parent.translate = true
	get_tree().paused = true
	parent.pause_mode = PAUSE_MODE_PROCESS
	if parent.camera != null:
		var camPose = parent.camera.global_position
		parent.camera.get_parent().remove_child(parent.camera)
		parent.get_parent().add_child(parent.camera)
		parent.camera.global_position = camPose

	if parent.movement.y > 1000 && Global.lives > 0:
		parent.movement = Vector2.ZERO
		Global.lives -= 1
		if Global.lives > 0:
			Global.main.change_scene(null,"FadeOut")
			parent.pause_mode = PAUSE_MODE_STOP
		else:
			Global.gameOver = true
