@tool
extends Node2D

## Vertical spinning pylon from Flying Battery Zone
## Author: DimensionWarped
## Note: This should be refactored into a ConnectableGimmick

## Vertical size of the pylon (center only - edges are constant sized)
@export var vert_size = 96
## How fast the player should be launched from the pylon when pressing jump
@export var launch_speed = 960
## How fast the player should be launching veritcally from the pylon after jumping
## off
@export var launch_vertical_speed = 110
## How fast the player climbs up/down the pylon
@export var climb_speed = 80

# An editor only variable. If last_size doesn't match vert_size during process
# in tool mode, we resize everything in the editor.
var last_size
# How much time it takes to make a full rotation in seconds. The full cycle lasts
# 32 frames in Sonic and Knuckles.
var rotate_time = (32.0 / 60.0)
# array of players currently interacting with the gimmick
var players = []
# array of players time currently spent rotating around the gimmick
var players_rotation_timer = []
# array of players z levels upon interacting with the gimmick. This is needed
# because the player's z level will be pushed behind the pylon and in front of
# the pylon depending on their position in the spinning animation and we need
# to be able to restore it when the player leaves the gimmick.
var players_z_level = []

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		last_size = vert_size
		
	var mainSprite = $FBZ_Pylon_Sprite
	var topSprite = $FBZ_Pylon_Top
	var bottomSprite = $FBZ_Pylon_Bottom
	var animator = $FBZ_Pylon_Animator
	var collision = $FBZ_Pylon_Area/FBZ_Pylon_Collision

	# Sizes the gimmick to match with the vert_size parameter
	last_size = vert_size
	mainSprite.set_region_rect(Rect2(0, 0, 48, vert_size))
	mainSprite.position = Vector2(0, -vert_size / 2.0 - bottomSprite.texture.get_height() / 2.0)
	topSprite.position = mainSprite.position + Vector2(0, (-vert_size / 2.0) - (topSprite.texture.get_height() / 4.0))
	bottomSprite.position = mainSprite.position + Vector2(0, (vert_size / 2.0) + (bottomSprite.texture.get_height() / 4.0) + 1)
	animator.play("main")
	
	var shape = RectangleShape2D.new()
	shape.size.y = vert_size
	shape.size.x = 12
	
	collision.set_shape(shape)
	collision.position = Vector2(0, -vert_size / 2.0 - bottomSprite.texture.get_height() / 2.0)
	
func process_game(delta):
	for i in players:
		var getIndex = players.find(i)
		var yInput = i.get_y_input()

		# If the player isn't on the bar, skip it.
		if i.currentState != i.STATES.ANIMATION:
			continue
		
		# Increment the rotation timer for the player
		players_rotation_timer[getIndex] += delta
		
		if (yInput == 0):
			i.movement.y = 0
		elif (yInput > 0):
			i.movement.y = climb_speed
		else:
			i.movement.y = -climb_speed
		i.movement.x = 0
		
		# Position the player based on their position in rotation.
		i.global_position.x = get_global_position().x + 7 * sin((players_rotation_timer[getIndex] / rotate_time * 2 * PI))
		
		if (i.global_position.y < get_global_position().y - vert_size - 4):
			i.global_position.y = get_global_position().y - vert_size - 4
			
		if (i.global_position.y > get_global_position().y - 30):
			i.global_position.y = get_global_position().y - 30
			
		# Animate the player based on their position in rotation.
		i.animator.seek(players_rotation_timer[getIndex] / rotate_time)
		
		if fmod((players_rotation_timer[getIndex] / rotate_time) - 0.25, 1.0) > 0.5:
			i.set_z_index(get_z_index() - 100)
		else:
			i.set_z_index(get_z_index() + 100)
			
		if (i.any_action_pressed()):
			i.set_z_index(players_z_level[getIndex])
			i.set_state(i.STATES.JUMP)
			# set animation to roll
			i.movement.y = -launch_vertical_speed
			if (i.is_left_held()):
				i.movement.x = -launch_speed
			else:
				i.movement.x = launch_speed

# Tool Function to reset the size and position of elements within the object based on vert_size	
func process_editor():
	var mainSprite = $FBZ_Pylon_Sprite
	var topSprite = $FBZ_Pylon_Top
	var bottomSprite = $FBZ_Pylon_Bottom
	var collision = $FBZ_Pylon_Area/FBZ_Pylon_Collision
	
	if (last_size == vert_size):
		return
	
	last_size = vert_size
	mainSprite.set_region_rect(Rect2(0, 0, 48, vert_size))
	mainSprite.position = Vector2(0, -vert_size / 2.0 - bottomSprite.texture.get_height() / 2.0)
	topSprite.position = mainSprite.position + Vector2(0, (-vert_size / 2.0) - (topSprite.texture.get_height() / 4.0))
	bottomSprite.position = mainSprite.position + Vector2(0, (vert_size / 2.0) + (bottomSprite.texture.get_height() / 4.0) + 1)

	var shape = RectangleShape2D.new()
	shape.size.y = vert_size / 2.0
	shape.size.x = 6
	
	collision.set_shape(shape)
	collision.position = Vector2(0, -vert_size / 2.0 - bottomSprite.texture.get_height() / 2.0)
	
func _process(delta):
	if Engine.is_editor_hint():
		return process_editor()

	process_game(delta)

func _draw():
	if Engine.is_editor_hint():
		pass

func _on_FBZ_Pylon_Area_body_entered(body):	
	if !players.has(body):
		players.append(body)
		players_rotation_timer.append(0)
		players_z_level.append(body.get_z_index())
		
	# The bar only spins one way, so the direction is always going to be forward.
	body.direction = 1
	body.sprite.flip_h = false
	
	# Play the swinging animation at 0 speed so we can control it manually.
	body.animator.play("swingVerticalBarManaged", -1, 0, false)
	
	body.set_state(body.STATES.ANIMATION,body.currentHitbox.HORIZONTAL)

func _on_FBZ_Pylon_Area_body_exited(body):
	remove_player(body)
	
func remove_player(player):
	if players.has(player):
		# Don't allow removal of someone who is still on the vertical bar. This can occur with
		# high speeds. Preventing this should be fine since the player will be brought back into
		# collision overlap range by virtue of being on the bar.
		if (player.currentState == player.STATES.ANIMATION):
			return
		player.animator.play("roll")
		player.set_state(player.STATES.AIR)
		# Clean out the player from all player-linked arrays.
		var getIndex = players.find(player)
		players.erase(player)
		players_rotation_timer.remove_at(getIndex)
		players_z_level.remove_at(getIndex)
