@tool
extends ConnectableGimmick

## Vertical spinning pylon from Flying Battery Zone
## Author: DimensionWarped

## Vertical size of the pylon (center only - edges are constant sized)
@export var vert_size = 96
## How fast the player should be launched from the pylon when pressing jump
@export var launch_speed = 960
## How fast the player should be launching veritcally from the pylon after jumping
## off
@export var launch_vertical_speed = 110
## How fast the player climbs up/down the pylon
@export var climb_speed = 80
## How far out from the center does the player rotate around the gimmick?
@export var rotation_magnitude = 7

# An editor only variable. If last_size doesn't match vert_size during process
# in tool mode, we resize everything in the editor.
var last_size

# How much time it takes to make a full rotation in seconds. The full cycle lasts
# 32 frames in Sonic and Knuckles.
var rotate_time = (32.0 / 60.0)
# array of players currently interacting with the gimmick
#var players = []
# array of players time currently spent rotating around the gimmick
#var players_rotation_timer = []
# array of players z levels upon interacting with the gimmick. This is needed
# because the player's z level will be pushed behind the pylon and in front of
# the pylon depending on their position in the spinning animation and we need
# to be able to restore it when the player leaves the gimmick.
#var players_z_level = []

# Called when the node enters the scene tree for the first time.
func _ready():
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
	bottomSprite.position = mainSprite.position + Vector2(0, (vert_size / 2.0) + (bottomSprite.texture.get_height() / 4.0))
	animator.play("main")
	
	var shape = RectangleShape2D.new()
	shape.size.y = vert_size
	shape.size.x = 12
	
	collision.set_shape(shape)
	collision.position = Vector2(0, -vert_size / 2.0 - bottomSprite.texture.get_height() / 2.0)
	

func check_grab(player: PlayerChar):
	if player.is_gimmick_locked_for_player(self):
		return false
	var player_state = player.get_state()
	
	if player_state == PlayerChar.STATES.RESPAWN:
		return false
		
	if player_state == PlayerChar.STATES.DIE:
		return false
		
	if player_state == PlayerChar.STATES.HIT:
		return false
	
	return true

func connect_player(player: PlayerChar):
	# attmept to connect to the gimmick. If failed, we give up this attempt.
	if player.set_active_gimmick(self) == false:
		return

	# XXX TODO: We need to clean up this hitbox setting stuff
	player.set_state(PlayerChar.STATES.GIMMICK, player.get_predefined_hitbox(PlayerChar.HITBOXES.HORIZONTAL))
	player.set_direction(PlayerChar.DIRECTIONS.RIGHT)
	player.get_avatar().get_animator().play("swingVerticalBarManaged", -1, 0.0)
	player.set_gimmick_var("VerticalPylonRotationTimer", 0.0)
	player.set_gimmick_var("VerticalPylonYPos", global_position.y - player.global_position.y)
	player.set_gimmick_var("VerticalPylonZIndex", player.z_index)
	player.movement = Vector2(0.0, 0.0)
	
func disconnect_player(player: PlayerChar):
	player.set_z_index(player.get_gimmick_var("VerticalPylonZIndex"))
	player.unset_active_gimmick()

	# We only change the player state on disconnect if they still in GIMMICK
	# when we got here.
	if player.get_state() == PlayerChar.STATES.GIMMICK:
		player.set_state(PlayerChar.STATES.JUMP)
		player.get_avatar().get_animator().play("roll")
	
	var unlock_func = func ():
		player.clear_single_locked_gimmick(self)
	
	var timer:SceneTreeTimer = get_tree().create_timer(0.25, false)
	timer.timeout.connect(unlock_func, CONNECT_DEFERRED)
	player.add_locked_gimmick(self)
	pass

func process_game(delta):
	var players_to_check = $FBZ_Pylon_Area.get_overlapping_bodies()
	for player: PlayerChar in players_to_check:
		if player.get_active_gimmick() != null:
			continue

		if check_grab(player):
			connect_player(player)
			continue
	
	for player: PlayerChar in Global.get_players_on_gimmick(self):	
		# Update the player rotation timer
		var player_rotation = player.get_gimmick_var("VerticalPylonRotationTimer") + delta
		player.set_gimmick_var("VerticalPylonRotationTimer", player_rotation)

		# Position the player based on their position in rotation.
		var rotation_phase = sin(player_rotation * 2.0 * PI / rotate_time)
		var x_offset = rotation_magnitude * rotation_phase
		player.global_position.x = global_position.x + x_offset
		
		# Move the player's relative position based on their input and clamp it
		# based on their relative position XXX TODO
		var relative_y_pos = player.get_gimmick_var("VerticalPylonYPos")

		var yInput = player.get_y_input()
		if yInput > 0:
			relative_y_pos -= climb_speed * delta
		elif yInput < 0:
			relative_y_pos += climb_speed * delta
			
		# Clamp the player's veritcal position
		if relative_y_pos > vert_size + 4:
			relative_y_pos = vert_size + 4
		elif relative_y_pos < 26:
			relative_y_pos = 26
			
		player.set_gimmick_var("VerticalPylonYPos", relative_y_pos)

		player.global_position.y = global_position.y - relative_y_pos
			
		# Animate the player based on their position in rotation.
		player.get_avatar().get_animator().seek(player_rotation / rotate_time)
		
		if fmod((player_rotation / rotate_time) - 0.25, 1.0) > 0.5:
			player.set_z_index(get_z_index() - 100)
		else:
			player.set_z_index(get_z_index() + 100)
			
		if (player.any_action_pressed()):
			player.movement.y = -launch_vertical_speed
			if (player.is_left_held()):
				player.movement.x = -launch_speed
			else:
				player.movement.x = launch_speed
			disconnect_player(player)
		
		if player.get_state() != PlayerChar.STATES.GIMMICK:
			disconnect_player(player)

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
	bottomSprite.position = mainSprite.position + Vector2(0, (vert_size / 2.0) + (bottomSprite.texture.get_height() / 4.0))

	var shape = RectangleShape2D.new()
	shape.size.y = vert_size / 1.0
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

## This will usually only be invoked if the player gets hit or another object
## forces the player off
func player_force_detach_callback(player : PlayerChar):
	disconnect_player(player)
	pass
