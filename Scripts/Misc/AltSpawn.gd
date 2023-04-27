extends Node2D

@export_enum("Sonic","Tails","Knuckles")var currentCharacter = 0
# alternative spawning location
func _ready():
	if currentCharacter == Global.PlayerChar1-1 and Global.currentCheckPoint == -1:
		Global.players[0].global_position = global_position
		Global.players[0].camera.global_position = global_position
