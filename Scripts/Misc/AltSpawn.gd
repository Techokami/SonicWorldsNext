@tool
extends Node2D

@export var current_character:Global.CHARACTERS = 1 as Global.CHARACTERS:
	set(value):
		# Reject the value if the user chose "None" from the editor
		if Engine.is_editor_hint() and value == Global.CHARACTERS.NONE:
			return
		current_character = value

# alternative spawning location
func _ready():
	if !Engine.is_editor_hint() and current_character == Global.PlayerChar1 and Global.currentCheckPoint == -1:
		Global.players[0].global_position = global_position
		Global.players[0].camera.global_position = global_position
