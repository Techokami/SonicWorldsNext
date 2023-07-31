extends Sprite2D
var getCam = null
var player = null

@onready var screenXSize = GlobalFunctions.get_screen_size().x

func _physics_process(_delta):
	# check if player.x position is greater then the post
	if Global.players[0].global_position.x > global_position.x and Global.players[0].global_position.y <= global_position.y and Global.stageClearPhase == 0:
		# set player variable
		player = Global.players[0]
		
		# Camera3D limit set
		player.limitLeft = global_position.x -screenXSize/2
		player.limitRight = global_position.x +(screenXSize/2)+48
		getCam = player.camera
		
		# play spinner
		$Animator.play("Spinner")
		match player.character:
			1:
				$Animator.queue("Tails")
			2:
				$Animator.queue("Knuckles")
			3:
				$Animator.queue("Amy")
			_:
				$Animator.queue("Sonic")
		$GoalPost.play()
		# set global stage clear phase to 1, 1 is used to stop the timer (see HUD script)
		Global.stageClearPhase = 1
		
		# wait for spinner to finish
		await $Animator.animation_finished
		# after finishing spin, set stage clear to 2 and disable the players controls,
		# stage clear is set to 2 so that the level ending doesn't start prematurely but we can track where the player is
		Global.stageClearPhase = 2
		player.playerControl = -1
		# put states under player in here if the state could end up getting the player soft locked
		var stateCancelList = [player.STATES.WALLCLIMB]
		for i in stateCancelList:
			if i == player.currentState:
				player.set_state(player.STATES.AIR)
		# set inputs to right
		player.inputs[player.INPUTS.XINPUT] = 1
		player.inputs[player.INPUTS.YINPUT] = 0
		player.inputs[player.INPUTS.ACTION] = 0
		# make partner move too
		if player.get("partner") != null:
			player.partner.inputs[player.INPUTS.XINPUT] = 1
			player.partner.inputs[player.INPUTS.YINPUT] = 0
			player.partner.inputs[player.INPUTS.ACTION] = 0
	
	# stage clear settings
	if Global.stageClearPhase != 0:
		# lock camera to self
		if getCam:
			getCam.global_position.x = global_position.x
		# if player greater then screen and stage clear phase is 2 then activate the stage clear sequence
		if player:
			if player.global_position.x > global_position.x+(screenXSize/2) and player.movement.x >= 0 and Global.stageClearPhase == 2:
				# stage clear won't work is stage clear phase isn't 0
				Global.stageClearPhase = 0
				Global.stage_clear()
				# set stage clear to 3, this will activate the HUD sequence
				Global.stageClearPhase = 3
