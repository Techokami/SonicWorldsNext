extends Sprite
var getCam = null
var player = null

func _physics_process(delta):
	if Global.players[0].global_position.x > global_position.x && Global.players[0].global_position.y <= global_position.y && Global.stageClearPhase == 0:
		player = Global.players[0]
		
		# Camera limit set
		player.limitLeft = global_position.x -320/2
		player.limitRight = global_position.x +(320/2)+48
		getCam = player.camera
		
		$Animator.play("Spinner")
		$Animator.queue("Sonic")
		$GoalPost.play()
		Global.stageClearPhase = 1
		yield($Animator,"animation_finished")
		Global.stageClearPhase = 2
		player.playerControl = 0
		player.inputs[player.INPUTS.XINPUT] = 1
		player.inputs[player.INPUTS.YINPUT] = 0
		
	if Global.stageClearPhase != 0:
		if getCam:
			getCam.global_position.x = global_position.x
		if player:
			if player.global_position.x > global_position.x+(320/2) && player.movement.x > 0 && Global.stageClearPhase == 2:
				Global.stageClearPhase = 0
				Global.stage_clear()
				Global.stageClearPhase = 3
