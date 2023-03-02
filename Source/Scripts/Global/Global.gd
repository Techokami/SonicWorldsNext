extends Node

# player pointers (0 is usually player 1)
var players = []
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
var nextZone = preload("res://Scene/Zones/BaseZone.tscn") # change this to the first level in the game (also set in "reset_values")
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
# this is reference in
# res://Scripts/Misc/HUD.gd
# res://Scripts/Objects/GoalPost.gd
var stageClearPhase = 0

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
# emeralds use bitwise flag operations, the equivelent for 7 emeralds would be 128
var emeralds = 0
# emerald bit flags
enum EMERALD {RED = 1, BLUE = 2, GREEN = 4, YELLOW = 8, CYAN = 16, SILVER = 32, PURPLE = 64}
var specialStageID = 0
var levelTime = 0 # the timer that counts down while the level isn't completed or in a special ring
var globalTimer = 0 # global timer, used as reference for animations
var maxTime = 60*10

# water level of the current level, setting this to null will disable the water
var waterLevel = null
var setWaterLevel = 0 # used by other nodes to change the water level
var waterScrollSpeed = 64 # used by other nodes for how fast to move the water to different levels

# characters (if you want more you should add one here, see the player script too for more settings)
enum CHARACTERS {NONE,SONIC,TAILS,KNUCKLES}
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
var zoomSize = 1

# Hazard type references
enum HAZARDS {NORMAL, FIRE, ELEC, WATER}

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
		var loadNode = get_tree().current_scene.filename
		var mainScene = load("res://Scene/Main.tscn").instantiate()
		get_tree().root.call_deferred("remove_child",get_tree().current_scene)
		#get_tree().root.current_scene.call_deferred("queue_free")
		get_tree().root.call_deferred("add_child",mainScene)
		mainScene.get_node("SceneLoader").get_child(0).nextScene = load(loadNode)
		await get_tree().process_frame
		get_tree().paused = false
		#mainScene.change_scene_to_file(load(loadNode))
	is_main_loaded = true

func _process(delta):
	# do a check for certain variables, if it's all clear then count the level timer up
	if stageClearPhase == 0 and !gameOver and !get_tree().paused and timerActive:
		levelTime += delta
	# count global timer if game isn't paused
	if !get_tree().paused:
		globalTimer += delta
	
# reset values, self explanatory, put any variables to their defaults in here
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

# use this to play a sound globally, use load("res:..") or a preloaded sound
func play_sound(sound = null):
	if sound != null:
		soundChannel.stream = sound
		soundChannel.play()

# add a score object, see res://Scripts/Misc/Score.gd for reference
func add_score(position = Vector2.ZERO,value = 0):
	var scoreObj = Score.instantiate()
	scoreObj.scoreID = value
	scoreObj.global_position = position
	add_child(scoreObj)

# use a check function to see if a score increase would go above 50,000
func check_score_life(scoreAdd = 0):
	if fmod(score,50000) > fmod(score+scoreAdd,50000):
		life.play()
		lives += 1
		effectTheme.volume_db = -100
		music.volume_db = -100
		bossMusic.volume_db = -100

# use this to set the stage clear theme, only runs if stageClearPhase isn't 0
func stage_clear():
	if stageClearPhase == 0:
		currentTheme = 2
		music.stream = themes[currentTheme]
		music.play()
		effectTheme.stop()
		bossMusic.stop()

# Godot doesn't like not having emit signal only done in other nodes so we're using a function to call it
func emit_stage_start():
	emit_signal("stage_started")

# save data settings
func save_settings():
	var file = ConfigFile.new()
	# save settings
	file.set_value("Volume","SFX",AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	file.set_value("Volume","Music",AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	
	file.set_value("Resolution","Zoom",zoomSize)
	file.set_value("Resolution","FullScreen",((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)))
	# save config and close
	file.save("user://Settings.cfg")

# load settings
func load_settings():
	var file = ConfigFile.new()
	var err = file.load("user://Settings.cfg")
	if err != OK:
		return false # Return false as an error
	
	if file.has_section_key("Volume","SFX"):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),file.get_value("Volume","SFX"))
	
	if file.has_section_key("Volume","Music"):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),file.get_value("Volume","Music"))
	
	if file.has_section_key("Resolution","Zoom"):
		zoomSize = file.get_value("Resolution","Zoom")
		get_window().set_size(get_viewport().get_visible_rect().size*zoomSize)
	
	if file.has_section_key("Resolution","FullScreen"):
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (file.get_value("Resolution","FullScreen")) else Window.MODE_WINDOWED
	
