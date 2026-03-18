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
		char_textures[0] = $Sprite.sprite_frames.get_frame_texture(&"default", 0) as Texture2D
		for char_name: String in Global.CHARACTERS.keys():
			if char_name != "NONE":
				char_textures[Global.CHARACTERS[char_name]] = \
					load("res://Graphics/Items/goal_post_%s.png" % char_name.to_lower()) as Texture2D
		# overwrite the texture in each 4'th frame (3, 7, 11, ..., 123) with a character-specific one,
		# but don't touch frame 127 yet, in case the player character will be changed mid-level
		# (this relies on Robotnik's frame position being (0,0) in the texture file)
		var frames: SpriteFrames = $Sprite.sprite_frames
		for i: int in range(3, 124, 4):
			frames.set_frame(&"spinner", i, char_textures[((i + 1) >> 2) % num_textures])

func _physics_process(_delta):
	var player: PlayerChar = Global.players[0]
	# check if player.x position is greater than the post
	if !Global.is_in_any_stage_clear_phase() and player.global_position.x > global_position.x and player.global_position.y <= global_position.y:
		
		# Camera limit set
		var half_screen_width: float = GlobalFunctions.get_screen_size().x / 2.0
		var camera: PlayerCamera = player.get_camera()
		camera.target_limit_left = global_position.x - half_screen_width
		camera.target_limit_right = global_position.x + half_screen_width + 48.0

		# set the texture for frame 127 to the one that corresponds to the player character
		# (this is not done in _ready, in case the character was changed mid-level)
		var sprite: AnimatedSprite2D = $Sprite
		sprite.sprite_frames.set_frame(&"spinner", 127, char_textures[Global.PlayerChar1])
		# play spinner
		sprite.play(&"spinner")
		$GoalPost.play()
		# set global stage clear phase to STARTED, this is used to stop the timer (see HUD script)
		Global.set_stage_clear_phase(Global.STAGE_CLEAR_PHASES.STARTED)
		
		# wait for spinner to finish
		await sprite.animation_finished
		# after finishing spin, set stage clear phase to GOALPOST_SPIN_END and disable the players controls,
		# stage clear phase is set to GOALPOST_SPIN_END so that the level ending doesn't start prematurely
		# but we can track where the player is
		Global.set_stage_clear_phase(Global.STAGE_CLEAR_PHASES.GOALPOST_SPIN_END)
		player.playerControl = -1
		# put states under player in here if the state could end up getting the player soft locked
		var state_cancel_list: Array[PlayerChar.STATES] = [
			PlayerChar.STATES.CHARACTERACTION,
			PlayerChar.STATES.GIMMICK
		]
		var partner: PlayerChar = player.get_partner()
		for i: PlayerChar in [ player, partner ] if partner != null else [ player ]:
			if i.get_state() in state_cancel_list:
				i.set_state(PlayerChar.STATES.AIR)
				i.get_avatar().get_animator().play(&"walk")
			# set inputs to right
			i.inputs[PlayerChar.INPUTS.XINPUT] = 1
			i.inputs[PlayerChar.INPUTS.YINPUT] = 0
			i.inputs[PlayerChar.INPUTS.ACTION] = 0
	
	# stage clear settings
	if Global.is_in_any_stage_clear_phase() and $Sprite.animation == "spinner":
		# lock camera to self
		player.get_camera().global_position.x = global_position.x
		# if player greater then screen and stage clear phase is GOALPOST_SPIN_END then activate the stage clear sequence
		if player.global_position.x > global_position.x+(GlobalFunctions.get_screen_size().x/2) and \
		   player.movement.x >= 0 and Global.get_stage_clear_phase() == Global.STAGE_CLEAR_PHASES.GOALPOST_SPIN_END:
			# temporarily set stage clear to NOT_STARTED so that the music can play
			Global.reset_stage_clear_phase()
			Global.stage_clear()
			# set stage clear phase to SCORE_TALLY, this will activate the HUD sequence
			Global.set_stage_clear_phase(Global.STAGE_CLEAR_PHASES.SCORE_TALLY)
