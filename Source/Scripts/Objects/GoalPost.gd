extends Sprite
var getCam = null
var player = null

func _physics_process(_delta):
	if Global.players[0].global_position.x > global_position.x and Global.players[0].global_position.y <= global_position.y and Global.stageClearPhase == 0:
		player = Global.players[0]
		
		# Camera limit set
		player.limitLeft = global_position.x -320/2
		player.limitRight = global_position.x +(320/2)+48
		getCam = player.camera
		
		$Animator.play("Spinner")
		match player.character:
			1:
				$Animator.queue("Tails")
			2:
				$Animator.queue("Knuckles")
			_:
				$Animator.queue("Sonic")
		$GoalPost.play()
		Global.stageClearPhase = 1
		yield($Animator,"animation_finished")
		Global.stageClearPhase = 2
		player.playerControl = -1
		# put states under player in here if the state could end up getting the player soft locked
		var stateCancelList = [player.STATES.WALLCLIMB]
		for i in stateCancelList:
			if i == player.currentState:
				player.set_state(player.STATES.AIR)
		
		player.inputs[player.INPUTS.XINPUT] = 1
		player.inputs[player.INPUTS.YINPUT] = 0
		player.inputs[player.INPUTS.ACTION] = 0
		# make partner move too
		if player.get("partner") != null:
			player.partner.inputs[player.INPUTS.XINPUT] = 1
			player.partner.inputs[player.INPUTS.YINPUT] = 0
			player.partner.inputs[player.INPUTS.ACTION] = 0
		
	if Global.stageClearPhase != 0:
		if getCam:
			getCam.global_position.x = global_position.x
		if player:
			if player.global_position.x > global_position.x+(320/2) and player.movement.x > 0 and Global.stageClearPhase == 2:
				Global.stageClearPhase = 0
				Global.stage_clear()
				Global.stageClearPhase = 3
