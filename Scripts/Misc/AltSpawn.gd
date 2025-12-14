extends Node2D

@export var current_character:Global.CHARACTERS = 1 as Global.CHARACTERS:
	set(value):
		current_character = value

# alternative spawning location
func _ready():
	if current_character == Global.PlayerChar1 and Global.currentCheckPoint == -1:
		Global.players[0].global_position = global_position
		Global.players[0].camera.global_position = global_position
