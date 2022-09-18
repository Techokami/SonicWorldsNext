extends Node

var originalFPS = 60
var players = []
var main = null
var hud = null
var checkPoints = []
var currentCheckPoint = -1
var checkPointTime = 0

var startScene = preload("res://Scene/Presentation/Title.tscn")
var nextZone = preload("res://Scene/Zones/BaseZone.tscn") # change this to the first level in the game (also set in "reset_values")
# use this to store the current state of the room, changing scene will clear everythin
var stageInstanceMemory = null
var stageLoadMemory = null

var Score = preload("res://Entities/Misc/Score.tscn")
const SCORE_COMBO = [1,2,3,4,4,4,4,4,4,4,4,4,4,4,4,5]

var timerActive = false
var stageClearPhase = 0
var gameOver = false

var zoomSize = 1
# Music
var musicParent = null
var music = null
var effectTheme = null
var drowning = null
var life = null
var themes = [preload("res://Audio/Soundtrack/1. SWD_Invincible.ogg"),preload("res://Audio/Soundtrack/2. SWD_SpeedUp.ogg"),preload("res://Audio/Soundtrack/4. SWD_StageClear.ogg")]
var currentTheme = 0

# Sound
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

var waterLevel = null
var setWaterLevel = 0 # used by other nodes
var waterScrollSpeed = 64 # used by other nodes

enum CHARACTERS {NONE,SONIC,TAILS,KNUCKLES}
var PlayerChar1 = CHARACTERS.SONIC
var PlayerChar2 = CHARACTERS.TAILS

# Level settings
var hardBorderLeft   = -100000000
var hardBorderRight  =  100000000
var hardBorderTop    = -100000000
var hardBorderBottom =  100000000

var animals = [0,1]

signal stage_started

# Level memory
# this value contains node paths and can be used for nodes to know if it's been collected from previous playthroughs
# the only way to reset permanent memory is to reset the game, this is used primarily for special stage rings
# Note: make sure you're not naming your level nodes the same thing, it's good practice but if the node's
# share the same paths there can be some overlap and some nodes may not spawn when they're meant to
var nodeMemory = []

# Hazards
enum HAZARDS {NORMAL, FIRE, ELEC, WATER}

func _ready():
	add_child(soundChannel)
	soundChannel.bus = "SFX"
	load_settings()

func _process(delta):
	originalFPS = 60#*Engine.time_scale
	if stageClearPhase == 0 and !gameOver and !get_tree().paused and timerActive:
		levelTime += delta
	if !get_tree().paused:
		globalTimer += delta
	

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

func play_sound(sound = null):
	if sound != null:
		soundChannel.stream = sound
		soundChannel.play()

func add_score(position = Vector2.ZERO,value = 0):
	var scoreObj = Score.instance()
	scoreObj.scoreID = value
	scoreObj.global_position = position
	add_child(scoreObj)

# give life if more score will go above 50,000
func check_score_life(scoreAdd = 0):
	if fmod(score,50000) > fmod(score+scoreAdd,50000):
		life.play()
		lives += 1
		effectTheme.volume_db = -100
		music.volume_db = -100

func stage_clear():
	if stageClearPhase == 0:
		currentTheme = 2
		music.stream = themes[currentTheme]
		music.play()
		effectTheme.stop()

func emit_stage_start():
	emit_signal("stage_started")

func save_settings():
	var file = ConfigFile.new()
	# save settings
	file.set_value("Volume","SFX",AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	file.set_value("Volume","Music",AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	
	file.set_value("Resolution","Zoom",zoomSize)
	file.set_value("Resolution","FullScreen",OS.window_fullscreen)
	# save config and close
	file.save("user://Settings.cfg")

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
		OS.set_window_size(get_viewport().get_visible_rect().size*zoomSize)
	
	if file.has_section_key("Resolution","FullScreen"):
		OS.window_fullscreen = file.get_value("Resolution","FullScreen")
	
