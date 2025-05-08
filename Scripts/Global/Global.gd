extends Node

# player pointers (0 is usually player 1)
var players: Array[PlayerChar] = []
# main object reference
var main = null
# hud object reference
var hud = null
# checkpoint memory
var checkPoints = []
# reference for the current checkpoint
var currentCheckPoint = -1
# the current level time from when the checkpoint got hit
var checkPointTime = 0

# the starting room, this is loaded on game resets, you may want to change this
var startScene = preload("res://Scene/Presentation/Title.tscn")
var nextZone = load("res://Scene/Zones/BaseZone.tscn") # change this to the first level in the game (also set in "reset_values")
# use this to store the current state of the room, changing scene will clear everythin
var stageInstanceMemory = null
var stageLoadMemory = null

# score instace for add_score()
var Score = preload("res://Entities/Misc/Score.tscn")
# order for score combo
const SCORE_COMBO = [1,2,3,4,4,4,4,4,4,4,4,4,4,4,4,5]

# timerActive sets if the stage timer should be going
var timerActive = false
var gameOver = false

# stage clear is used to identify the current state of the stage clear sequence
# this is referenced in
# res://Scripts/Global/Main.gd
# res://Scripts/Misc/HUD.gd
# res://Scripts/Objects/Capsule.gd
# res://Scripts/Objects/GoalPost.gd
# res://Scripts/Player/Player.gd
enum STAGE_CLEAR_PHASES { NOT_STARTED, STARTED, GOALPOST_SPIN_END, SCORE_TALLY }
var _stage_clear_phase: STAGE_CLEAR_PHASES = STAGE_CLEAR_PHASES.NOT_STARTED:
	get = get_stage_clear_phase, set = set_stage_clear_phase
func get_stage_clear_phase() -> STAGE_CLEAR_PHASES:
	return _stage_clear_phase
func set_stage_clear_phase(value: STAGE_CLEAR_PHASES) -> void:
	_stage_clear_phase = value
func is_in_any_stage_clear_phase() -> bool:
	return get_stage_clear_phase() != STAGE_CLEAR_PHASES.NOT_STARTED
func reset_stage_clear_phase() -> void:
	set_stage_clear_phase(Global.STAGE_CLEAR_PHASES.NOT_STARTED)

# Music
var musicParent = null
var music = null
var bossMusic = null
var effectTheme = null
var drowning = null
var life = null
# song themes to play for things like invincibility and speed shoes
var themes = [preload("res://Audio/Soundtrack/1. SWD_Invincible.ogg"),preload("res://Audio/Soundtrack/2. SWD_SpeedUp.ogg"),preload("res://Audio/Soundtrack/4. SWD_StageClear.ogg")]
# index for current theme
var currentTheme = 0

# Sound, used for play_sound (used for a global sound, use this if multiple nodes use the same sound)
var soundChannel = AudioStreamPlayer.new()

# Gameplay values
var score = 0
var lives = 3
var continues = 0
# emeralds use bitwise flag operations, the equivelent for 7 emeralds would be 127
var emeralds = 0
# emerald bit flags
enum EMERALD {RED = 1, BLUE = 2, GREEN = 4, YELLOW = 8, CYAN = 16, SILVER = 32, PURPLE = 64}
var specialStageID = 0
var level = null # reference to the currently active level
var levelTime = 0 # the timer that counts down while the level isn't completed or in a special ring
var globalTimer = 0 # global timer, used as reference for animations
var maxTime = 60*10

# water level of the current level, setting this to null will disable the water
var waterLevel = null
var setWaterLevel = 0 # used by other nodes to change the water level
var waterScrollSpeed = 64 # used by other nodes for how fast to move the water to different levels

# characters (if you want more you should add one here, see the player script too for more settings)
enum CHARACTERS {NONE,SONIC,TAILS,KNUCKLES,AMY,SHADOW}

## Which multiplayer mode is in use alters some aspects of how the second (and on if that's ever
## implemented) works. Note that this is separate from concepts like split screen and it does not
## inherently set up a competitive 
##
## This is also a work in progress, not all intended features are currently implemented.
##
## NORMAL - Additional players are partner characters. They can't collect monitors. Rings they
##          collect are given to player 1. They don't die on hit. If the second controller is idle
##          for an extended period of time, Partner automation will take over. This is the normal
##          'little brother mode' multiplayer that you have in single player mode from the Genesis
##          games.
##  PEERS - Additional players are their own players. They can collect monitors. They get their
##          own rings. They take damage normally. They never get taken over by automation. They
##          have their own score count.
##          the main difference between this mode and VERSUS mode is that partner actions (and
##          Tails being able to carry a player around is the only one of these) work in this mode.
##          Also, when an act is finished, both players pass at the same time.
## VERSUS - Same as PEERS, but partner actions are disabled. When a Sign Post victory condition is
##          passed, the level does not immediately end and score is not tallied. Instead the final
##          time and ring bonus are stored for use in a results screen.
enum MULTIMODE {NORMAL = 0, PEERS = 1, VERSUS = 2}
var multiplayer_mode = MULTIMODE.NORMAL

# autofill the array with capitalized names from enum CHARACTERS
var character_names: Array = \
	CHARACTERS.keys().map(func(char_name: String): return char_name.capitalize())

var PlayerChar1 = CHARACTERS.SONIC
var PlayerChar2 = CHARACTERS.TAILS

# Level settings
var hardBorderLeft   = -100000000
var hardBorderRight  =  100000000
var hardBorderTop    = -100000000
var hardBorderBottom =  100000000

# Animal spawn type reference, see the level script for more information on the types
var animals = [0,1]

# emited when a stage gets started
signal stage_started

# Level memory
# this value contains node paths and can be used for nodes to know if it's been collected from previous playthroughs
# the only way to reset permanent memory is to reset the game, this is used primarily for special stage rings
# Note: make sure you're not naming your level nodes the same thing, it's good practice but if the node's
# share the same paths there can be some overlap and some nodes may not spawn when they're meant to
var nodeMemory = []

# Game settings
var zoom_size = 1.0
var smoothRotation = 0
enum TIME_TRACKING_MODES { STANDARD, SONIC_CD }
var time_tracking:TIME_TRACKING_MODES = TIME_TRACKING_MODES.STANDARD

## Hazard type references
enum HAZARDS {NORMAL, FIRE, ELEC, WATER}

# Layers references
enum LAYERS {LOW, HIGH}

# Debugging
var is_main_loaded = false

func _ready():
	# set sound settings
	add_child(soundChannel)
	soundChannel.bus = "SFX"
	# load game data
	load_settings()
	
	# check if main scene is root (prevents crashing if you started from another scene)
	if !(get_tree().current_scene is MainGameScene):
		get_tree().paused = true
		# change scene root to main scene, keep current scene in memory
		var loadNode = get_tree().current_scene.scene_file_path
		var mainScene = load("res://Scene/Main.tscn").instantiate()
		get_tree().root.call_deferred("remove_child",get_tree().current_scene)
		#get_tree().root.current_scene.call_deferred("queue_free")
		get_tree().root.call_deferred("add_child",mainScene)
		mainScene.get_node("SceneLoader").get_child(0).nextScene = load(loadNode)
		await get_tree().process_frame
		get_tree().paused = false
	is_main_loaded = true
	

func _process(delta):
	# do a check for certain variables, if it's all clear then count the level timer up
	if !is_in_any_stage_clear_phase() and !gameOver and !get_tree().paused and timerActive:
		levelTime += delta
	# count global timer if game isn't paused
	if !get_tree().paused:
		globalTimer += delta
	

## reset values, self explanatory, put any variables to their defaults in here
func reset_values():
	lives = 3
	score = 0
	continues = 0
	levelTime = 0
	emeralds = 0
	specialStageID = 0
	checkPoints = []
	checkPointTime = 0
	currentCheckPoint = -1
	animals = [0,1]
	nodeMemory = []
	nextZone = load("res://Scene/Zones/BaseZone.tscn")


## use this to play a sound globally, use load("res:..") or a preloaded sound
func play_sound(sound = null) -> void:
	if sound != null:
		soundChannel.stream = sound
		soundChannel.play()


## add a score object, see res://Scripts/Misc/Score.gd for reference
func add_score(position = Vector2.ZERO,value = 0) -> void:
	var scoreObj = Score.instantiate()
	scoreObj.scoreID = value
	scoreObj.global_position = position
	add_child(scoreObj)


## use a check function to see if a score increase would go above 50,000
func check_score_life(scoreAdd: int = 0) -> void:
	if fmod(score,50000) > fmod(score+scoreAdd,50000):
		life.play()
		lives += 1
		effectTheme.volume_db = -100
		music.volume_db = -100
		bossMusic.volume_db = -100


## use this to set the stage clear theme, only runs if stage clear phase is NONE
func stage_clear() -> void:
	if !is_in_any_stage_clear_phase():
		currentTheme = 2
		music.stream = themes[currentTheme]
		music.play()
		effectTheme.stop()
		bossMusic.stop()


## Emit the stage started signal
func emit_stage_start() -> void:
	stage_started.emit()


## save data settings
func save_settings() -> void:
	var file = ConfigFile.new()
	# save settings
	file.set_value("Volume","SFX",AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	file.set_value("Volume","Music",AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	
	file.set_value("Resolution","Zoom",zoom_size)
	file.set_value("Gameplay","SmoothRotation",smoothRotation)
	file.set_value("Resolution","FullScreen",((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)))

	file.set_value("HUD","TimeTracking",time_tracking)

	# save config and close
	file.save("user://Settings.cfg")


## load settings
func load_settings() -> void:
	var file = ConfigFile.new()
	var err = file.load("user://Settings.cfg")
	if err != OK:
		return
	
	if file.has_section_key("Volume","SFX"):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),file.get_value("Volume","SFX"))
		# Set bus mute state
		AudioServer.set_bus_mute(
		AudioServer.get_bus_index("SFX"), # Auidio bus to mute
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")) <= -40.0 # True if < -40.0
		)
	
	if file.has_section_key("Volume","Music"):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),file.get_value("Volume","Music"))
		# Set bus mute state
		AudioServer.set_bus_mute(
		AudioServer.get_bus_index("Music"), # Auidio bus to mute
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) <= -40.0 # True if < -40.0
		)
	
	if file.has_section_key("Resolution","Zoom"):
		zoom_size = file.get_value("Resolution","Zoom")
		resize_window(zoom_size)
	
	if file.has_section_key("Gameplay","SmoothRotation"):
		smoothRotation = file.get_value("Gameplay","SmoothRotation")
	
	if file.has_section_key("Resolution","FullScreen"):
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (file.get_value("Resolution","FullScreen")) else Window.MODE_WINDOWED

	if file.has_section_key("HUD","TimeTracking"):
		time_tracking = file.get_value("HUD","TimeTracking")
		if time_tracking < 0 or time_tracking >= TIME_TRACKING_MODES.size():
			time_tracking = TIME_TRACKING_MODES.STANDARD


func resize_window(new_zoom_size):
	var window = get_window()
	var new_size = Vector2i((get_viewport().get_visible_rect().size*new_zoom_size).round())
	window.set_position(window.get_position()+(window.size-new_size)/2)
	window.set_size(new_size)
	zoom_size = new_zoom_size
	
	
func get_zoom_size() -> float:
	return zoom_size


## Gets the main player.
func get_first_player() -> PlayerChar:
	return players[0]


## Useful for checking triggers that require specifically the first player to be on a gimmick	
func get_first_player_gimmick() -> ConnectableGimmick:
	return players[0].get_active_gimmick()


## Useful for gimmicks that can activate if any player is attached that don't need data about
## the specific player. A simple boolean of whether or not there is a player on a given
## ConnectableGimmick.
func is_any_player_on_gimmick(gimmick: ConnectableGimmick) -> bool:
	for player in players:
		if player.get_active_gimmick() == gimmick:
			return true
	return false


## Useful for gimmicks that need to potentially iterate through all attached players
func get_players_on_gimmick(gimmick) -> Array[PlayerChar]:
	var players_on_gimmick: Array[PlayerChar] = []
	for player in players:
		if player.get_active_gimmick() == gimmick:
			players_on_gimmick.append(player)
	return players_on_gimmick


## Simple check to see if the player is the first char
func is_player_first(player : PlayerChar) -> bool:
	if players[0] == player:
		return true
	return false


## Gets the index of the player selected
## @param player Which player you are checking
## @retval 0-N index of the player with 0 being player 1 and higher numbers
##             being later players
## @retval -1 if the player isn't in the inbox. That should be impossible unless
##            you make an orphaned player for some reason.
func get_player_index(player : PlayerChar) -> int:
	return players.find(player)


## get the current active camera
func getCurrentCamera2D() -> Camera2D:
	var viewport = get_viewport()
	if not viewport:
		return null
	var camerasGroupName = "__cameras_%d" % viewport.get_viewport_rid().get_id()
	var cameras = get_tree().get_nodes_in_group(camerasGroupName)
	for camera in cameras:
		if camera is Camera2D and camera.enabled:
			return camera
	return null


## the original game logic runs at 60 fps, this function is meant to be used to help calculate this,
## usually a division by the normal delta will cause the game to freak out at different FPS speeds
func div_by_delta(delta) -> float:
	return 0.016667*(0.016667/delta)


## get window size resolution as a vector2
func get_screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size
	
	
## Sets the current level (used as part of a level ready script usually)
func set_level(new_level: Level) -> void:
	self.level = new_level


## Gets the current level (useful for always knowing where the active level root is)
func get_level() -> Level:
	return self.level


## Gets the name of a character
func get_character_name(which: CHARACTERS) -> String:
	return character_names[which]


## Gets the current multiplayer mode	
func get_multimode() -> MULTIMODE:
	return multiplayer_mode


## Sets the multiplayer mode to the requested value
func set_multimode(new_multimode: MULTIMODE) -> void:
	self.multiplayer_mode = new_multimode


## Cycles the multiplayer mode
func cycle_multimode() -> void:
	self.multiplayer_mode = (self.multiplayer_mode + 1) % MULTIMODE.size() as MULTIMODE
