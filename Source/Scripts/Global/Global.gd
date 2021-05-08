extends Node

var originalFPS = 60;
var players = [];

# Gameplay values
var score = 0;
var lives = 3;
var continues = 0;
var levelTime = 0;


func _process(delta):
	originalFPS = 60*Engine.time_scale;
	levelTime += delta;
