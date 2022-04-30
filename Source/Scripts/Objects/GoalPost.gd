extends Sprite
var completeState = 0
var getCam = null
var player = null

func _physics_process(delta):
	if Global.players[0].global_position.x > global_position.x && Global.players[0].global_position.y <= global_position.y && completeState == 0:
		player = Global.players[0]
		
		# Camera limit set
		player.camera.limit_left = global_position.x -320/2
		player.camera.limit_right = global_position.x +(320/2)+48
		getCam = player.camera
		
		$Animator.play("Spinner")
		$Animator.queue("Sonic")
		$GoalPost.play()
		completeState = 1
		yield($Animator,"animation_finished")
		completeState = 2
		player.playerControl = 0
		player.inputs[player.INPUTS.XINPUT] = 1
		player.inputs[player.INPUTS.YINPUT] = 0
		
	if completeState != 0:
		if getCam:
			getCam.global_position.x = global_position.x
		if player:
			if player.global_position.x > global_position.x+(320/2) && !Global.stageClear && player.movement.x > 0 && completeState == 2:
				completeState = 3
				Global.stage_clear()
