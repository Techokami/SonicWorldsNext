extends PlayerState

func _ready():
	invulnerability = true # ironic

func _physics_process(delta):
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
			Global.checkPointRings = 0
			# check if lives are remaining or death was a time over
			if Global.lives > 0 and Global.levelTime < Global.maxTime:
				Main.change_scene(Global.currentZone,"FadeOut")
				parent.process_mode = PROCESS_MODE_PAUSABLE
			else:
				Global.gameOver = true
				# reset checkpoint time
				Global.checkPointTime = 0
	else:
	# if not run respawn code
		if parent.movement.y > 1000:
			parent.respawn()
