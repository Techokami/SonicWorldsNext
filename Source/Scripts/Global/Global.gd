extends Node

var originalFPS = 60
var players = []
var main
var checkPoints = []
var currentCheckPoint = -1

var startScene = preload("res://Scene/Title.tscn")

# Music
var music = null
var effectTheme = null
var life = null
var themes = [preload("res://Audio/Soundtrack/1. SWD_Invincible.ogg"),preload("res://Audio/Soundtrack/2. SWD_SpeedUp.ogg")]
var currentTheme = 0

# Gameplay values
var score = 0
var lives = 3
var continues = 0
var levelTime = 0

var waterLevel = null

func _process(delta):
	originalFPS = 60*Engine.time_scale
	levelTime += delta

func reset_values():
	lives = 3
	score = 0
	continues = 0
	levelTime = 0
	checkPoints = []
