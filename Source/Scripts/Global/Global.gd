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

var Score = preload("res://Entities/Misc/Score.tscn")
const SCORE_COMBO = [1,2,3,4,4,4,4,4,4,4,4,4,4,4,4,5]

var stageClearPhase = 0
var gameOver = false

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
var emeralds = 0
var levelTime = 0 # the timer that counts down while the level isn't completed
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

# Hazards
enum HAZARDS {NORMAL, FIRE, ELEC, WATER}

func _ready():
	add_child(soundChannel)
	soundChannel.bus = "SFX"

func _process(delta):
	originalFPS = 60#*Engine.time_scale
	if stageClearPhase == 0 && !gameOver && !get_tree().paused:
		levelTime += delta
	if !get_tree().paused:
		globalTimer += delta
	

func reset_values():
	lives = 3
	score = 0
	continues = 0
	levelTime = 0
	emeralds = 0
	checkPoints = []
	checkPointTime = 0
	currentCheckPoint = -1
	animals = [0,1]
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
		music.stream = themes[2]
		music.play()
		effectTheme.stop()
