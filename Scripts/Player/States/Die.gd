extends PlayerState

func _ready():
	invulnerability = true # ironic


func state_physics_process(delta: float) -> void:
	# gravity
	parent.movement.y += parent.grv/GlobalFunctions.div_by_delta(delta)
	# do allowTranslate to avoid collision
	parent.allowTranslate = true
	
	# check if main player
	if parent.playerControl == 1:
		# check if speed above certain threshold
		if parent.movement.y > 1000 and Global.lives > 0 and !Global.gameOver:
			parent.movement = Vector2.ZERO
			Global.lives -= 1
			# check if lives are remaining or death was a time over
			if Global.lives > 0 and Global.levelTime < Global.maxTime:
				Global.main.change_scene_to_file(null,"FadeOut")
				parent.process_mode = PROCESS_MODE_PAUSABLE
			else:
				Global.gameOver = true
				# reset checkpoint time
				Global.checkPointTime = 0
	else:
	# if not run respawn code
		if parent.movement.y > 1000:
			parent.respawn()
