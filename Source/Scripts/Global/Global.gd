extends Node

var originalFPS = 60
var players = []
var main = null
var hud = null
var checkPoints = []
var currentCheckPoint = -1

var startScene = preload("res://Scene/Title.tscn")
var nextZone = preload("res://Scene/Zones/BaseZone.tscn")

var Score = preload("res://Entities/Misc/Score.tscn")
const SCORE_COMBO = [1,2,3,4,4,4,4,4,4,4,4,4,4,4,4,5]

var stageClearPhase = 0
var gameOver = false

# Music
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
var levelTime = 0
var maxTime = 60*10

var waterLevel = null

enum CHARACTERS {NONE,SONIC,TAILS}
var PlayerChar1 = CHARACTERS.SONIC
var PlayerChar2 = CHARACTERS.TAILS

# Level settings
var hardBorderLeft   = -100000000
var hardBorderRight  =  100000000
var hardBorderTop    = -100000000
var hardBorderBottom =  100000000

# Hazards
enum HAZARDS {NORMAL, FIRE, ELEC, WATER}

signal stage_started

func _ready():
	add_child(soundChannel)
	soundChannel.bus = "SFX"

func _process(delta):
	originalFPS = 60*Engine.time_scale
	if stageClearPhase == 0 && !gameOver && !get_tree().paused:
		levelTime += delta
	

func reset_values():
	lives = 3
	score = 0
	continues = 0
	levelTime = 0
	checkPoints = []
	nextZone = load("res://Scene/Zones/BaseZone.tscn")

func play_sound(sound = null):
	if sound != null:
		soundChannel.stream = sound
		soundChannel.play()

func score(position = Vector2.ZERO,value = 0):
	var scoreObj = Score.instance()
	scoreObj.scoreID = value
	scoreObj.global_position = position
	add_child(scoreObj)

func stage_clear():
	if stageClearPhase == 0:
		music.stream = themes[2]
		music.play()
