extends Node

var originalFPS = 60;
var players = [];
var main

# Music
var music = null
var effectTheme = null
var life = null
var themes = [preload("res://Audio/Soundtrack/1. SWD_Invincible.ogg"),preload("res://Audio/Soundtrack/2. SWD_SpeedUp.ogg")]
var currentTheme = 0

# Gameplay values
var score = 0;
var lives = 3;
var continues = 0;
var levelTime = 0;


func _process(delta):
	originalFPS = 60*Engine.time_scale;
	levelTime += delta;
