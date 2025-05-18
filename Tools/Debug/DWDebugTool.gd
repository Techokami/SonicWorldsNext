## This tool provides functions that are useful for testing gimmicks for things
## like how the player reacts while attached to them them when they get hit by
## something or how they react when something pushes them off of it or if they
## touch the ground while on it. To use it, simply add the node to your scene
## (preferably somewhere out of the way) and use the keys that it checks to
## have certain effects.
##
## k - hurts the first player
## j - hurts the second player
## l - sets a return position for use with ;
## ; - teleports one or both players to the return position set with l
## u - places the big brick underneath the player and has it slowly move upwards
## i - places the big brick above the player and has it slowly move downwards
## o - places the big brick to the left of the player and has it slowly move
##     right
## p - places the big brick to the right of the player and has it slowly move
##     left
## m - Gives the player some rings
## , - Cycles through available shields
## . - Toggles physics slowdown to 1/8th scale
## / - Forces the partner to 'respawn'

extends Node2D

var brick_movement = Vector2(0, 0)
var teleport_location = null
var be_slow = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func _physics_process(_delta: float) -> void:
	$BigMovingBrick.global_position += brick_movement
	
func try_cheat():
	# Hurt the player tool
	if Input.is_key_pressed(KEY_K):
		Global.players[0].hit_player()
		return KEY_K

	# Hurt the second player player tool
	if Input.is_key_pressed(KEY_J) and Global.players.size() > 1:
		Global.players[1].hit_player()
		return KEY_J
		
	# Set the teleport location based on the player's current position
	if Input.is_key_pressed(KEY_L):
		teleport_location = Global.players[0].global_position
		return KEY_L
		
	if Input.is_key_pressed(KEY_SEMICOLON):
		if teleport_location == null:
			return 0
		
		Global.players[0].global_position = teleport_location
		if Global.players.size() > 1:
			Global.players[1].global_position = teleport_location
		return KEY_SEMICOLON

	if Input.is_key_pressed(KEY_M):
		Global.players[0].rings += 3
		return KEY_M
		
	if Input.is_key_pressed(KEY_COMMA):
		if Global.players[0].is_in_water():
			# if the player is in water, the only bubble and normal shield are useful. We'll just
			# always go with water to avoid extra conditions.
			Global.players[0].set_shield(PlayerChar.SHIELDS.BUBBLE)
		else:
			# Otherwise cycle the shields in order
			Global.players[0].set_shield((Global.players[0].shield + 1) % Global.players[0].SHIELDS.COUNT)
		return KEY_COMMA
		
	# Place the test block below the player and make it move upwards
	if Input.is_key_pressed(KEY_U):
		$BigMovingBrick.global_position = Global.players[0].global_position + Vector2(0, 160)
		brick_movement = Vector2(0, -2)
		return KEY_U

	# Place the test block above the player and make it move downwards
	if Input.is_key_pressed(KEY_I):
		$BigMovingBrick.global_position = Global.players[0].global_position + Vector2(0, -160)
		brick_movement = Vector2(0, 2)
		return KEY_I
	
	# Place the test block left of the player and make it move right
	if Input.is_key_pressed(KEY_O):
		$BigMovingBrick.global_position = Global.players[0].global_position + Vector2(-160, 0)
		brick_movement = Vector2(2, 0)
		return KEY_O
	
	# Place the test block right of the player and make it move left
	if Input.is_key_pressed(KEY_P):
		$BigMovingBrick.global_position = Global.players[0].global_position + Vector2(160, 0)
		brick_movement = Vector2(-2, 0)
		return KEY_P
	
	if Input.is_key_pressed(KEY_PERIOD):
		if be_slow:
			Engine.time_scale = 1.0
			be_slow = false
		else:
			Engine.time_scale = 0.125
			be_slow = true
		return KEY_PERIOD
	
	if Input.is_key_pressed(KEY_SLASH):
		if Global.players[1] != null:
			Global.players[1].respawn()
	
	
	return 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
var just_pressed = null
func _process(_delta: float) -> void:
	
	if just_pressed != null and Input.is_key_pressed(just_pressed):
		return
		
	just_pressed = null
	
	var got_back = try_cheat()
	
	if got_back != 0:
		just_pressed = got_back
	
	pass
