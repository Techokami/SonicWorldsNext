extends "res://Scripts/Player/State.gd"

func _physics_process(delta):
	parent.movement.y += parent.grv/delta
	parent.translate = true
	#get_tree().paused = true
	#parent.pause_mode = PAUSE_MODE_PROCESS
	
	if parent.playerControl == 1:
		if parent.movement.y > 1000 && Global.lives > 0 && !Global.gameOver:
			parent.movement = Vector2.ZERO
			Global.lives -= 1
			if Global.lives > 0 && Global.levelTime < Global.maxTime:
				Global.main.change_scene(null,"FadeOut")
				parent.pause_mode = PAUSE_MODE_STOP
			else:
				Global.gameOver = true
	else:
		if parent.movement.y > 1000:
			parent.respawn()
