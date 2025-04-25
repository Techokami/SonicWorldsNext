extends Node2D

# textures for character-specific frames (0 is for Robotnik)
static var char_textures: Array[Texture2D] = []

var getCam = null
var player = null

var screenXSize = 0

func _ready():
	# since char_textures is static, the following code will only run once,
	# even if the level contains more than 1 goal post, and even if it restarts
	if char_textures.size() == 0:
		# load textures for character-specific frames
		char_textures.resize(Global.CHARACTERS.size())
		char_textures[0] = $Sprite.sprite_frames.get_frame_texture("default", 0) as Texture2D
		for char_name: String in Global.CHARACTERS.keys():
			if char_name != "NONE":
				char_textures[Global.CHARACTERS[char_name]] = \
					load("res://Graphics/Items/goal_post_%s.png" % char_name.to_lower()) as Texture2D
		# overwrite the texture in each 4'th frame (3, 7, 11, ..., 123) with a character-specific one,
		# but don't touch frame 127 yet, in case the player character will be changed mid-level
		for i in 128 / 4 - 1:
			$Sprite.sprite_frames.set_frame("spinner", i * 4 + 3, char_textures[(i + 1) % char_textures.size()])

func _physics_process(_delta):
	# check if player.x position is greater than the post
	if Global.stageClearPhase == 0 and Global.players[0].global_position.x > global_position.x and Global.players[0].global_position.y <= global_position.y:
		# set player variable
		player = Global.players[0]
		
		# Camera limit set
		screenXSize = GlobalFunctions.get_screen_size().x
		player.limitLeft = global_position.x -screenXSize/2
		player.limitRight = global_position.x +(screenXSize/2)+48
		getCam = player.camera

		# set the texture for frame 127 to the one that corresponds to the player character
		# (this is not done in _ready, in case the character was changed mid-level)
		$Sprite.sprite_frames.set_frame("spinner", 127, char_textures[Global.PlayerChar1])
		# play spinner
		$Sprite.play("spinner")
		$GoalPost.play()
		# set global stage clear phase to 1, 1 is used to stop the timer (see HUD script)
		Global.stageClearPhase = 1
		
		# wait for spinner to finish
		await $Sprite.animation_finished
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
