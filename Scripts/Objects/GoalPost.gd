extends Node2D

# textures for character-specific frames (0 is for Robotnik)
static var char_textures: Array[Texture2D] = []

func _ready():
	# since char_textures is static, the following code will only run once,
	# even if the level contains more than 1 goal post, and even if it restarts
	if char_textures.is_empty():
		# load textures for character-specific frames
		var num_textures: int = Global.CHARACTERS.size()
		char_textures.resize(num_textures)
		char_textures[0] = $Sprite.sprite_frames.get_frame_texture("default", 0) as Texture2D
		for char_name: String in Global.CHARACTERS.keys():
			if char_name != "NONE":
				char_textures[Global.CHARACTERS[char_name]] = \
					load("res://Graphics/Items/goal_post_%s.png" % char_name.to_lower()) as Texture2D
		# overwrite the texture in each 4'th frame (3, 7, 11, ..., 123) with a character-specific one,
		# but don't touch frame 127 yet, in case the player character will be changed mid-level
		# (this relies on Robotnik's frame position being (0,0) in the texture file)
		for i in 128 / 4 - 1:
			$Sprite.sprite_frames.set_frame("spinner", 3 + i * 4, char_textures[(i + 1) % num_textures])

func _physics_process(_delta):
	var player: PlayerChar = Global.players[0]
	# check if player.x position is greater than the post
	if !Global.is_in_any_stage_clear_phase() and player.global_position.x > global_position.x and player.global_position.y <= global_position.y:

		
		# Camera limit set
		var screen_width: float = GlobalFunctions.get_screen_size().x
		player.limitLeft = global_position.x - screen_width/2
		player.limitRight = global_position.x + (screen_width/2) + 48

		# set the texture for frame 127 to the one that corresponds to the player character
		# (this is not done in _ready, in case the character was changed mid-level)
		$Sprite.sprite_frames.set_frame("spinner", 127, char_textures[Global.PlayerChar1])
		# play spinner
		$Sprite.play("spinner")
		$GoalPost.play()
		# set global stage clear phase to STARTED, this is used to stop the timer (see HUD script)
		Global.set_stage_clear_phase(Global.STAGE_CLEAR_PHASES.STARTED)
		
		# wait for spinner to finish
		await $Sprite.animation_finished
		# after finishing spin, set stage clear phase to GOALPOST_SPIN_END and disable the players controls,
		# stage clear phase is set to GOALPOST_SPIN_END so that the level ending doesn't start prematurely
		# but we can track where the player is
		Global.set_stage_clear_phase(Global.STAGE_CLEAR_PHASES.GOALPOST_SPIN_END)
		player.playerControl = -1
		# put states under player in here if the state could end up getting the player soft locked
		var stateCancelList = [PlayerChar.STATES.WALLCLIMB, PlayerChar.STATES.ANIMATION]
		for i in stateCancelList:
			if i == player.get_state():
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
	if Global.is_in_any_stage_clear_phase() and $Sprite.animation == "spinner":
		# lock camera to self
		player.camera.global_position.x = global_position.x
		# if player greater then screen and stage clear phase is GOALPOST_SPIN_END then activate the stage clear sequence
		if player.global_position.x > global_position.x+(GlobalFunctions.get_screen_size().x/2) and \
		   player.movement.x >= 0 and Global.get_stage_clear_phase() == Global.STAGE_CLEAR_PHASES.GOALPOST_SPIN_END:
			# temporarily set stage clear to NOT_STARTED so that the music can play
			Global.reset_stage_clear_phase()
			Global.stage_clear()
			# set stage clear phase to SCORE_TALLY, this will activate the HUD sequence
			Global.set_stage_clear_phase(Global.STAGE_CLEAR_PHASES.SCORE_TALLY)
