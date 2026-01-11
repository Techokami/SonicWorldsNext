## Catapult gimmick from Flying Battery Zone.[br]
## Author: Stanislav Gromov (with help and guidance from DimensionWarped).
@tool
class_name CatapultGimmick extends ConnectableGimmick


# TODO: Maybe move this enum into `Global` and reuse it for `PlayerChar` and other gimmicks?
enum _DIRECTIONS { LEFT, RIGHT }
## Direction the catapult faces and launches the player in.
@export var direction: _DIRECTIONS = _DIRECTIONS.RIGHT:
	set(value):
		direction = value
		scale.x = 1.0 if value == _DIRECTIONS.RIGHT else -1.0
		_calculate_launch_velocity()

## Velocity the catapult starts moving with.[br]
## In Sonic 3 & Knuckles it's [code]0[/code] (the catapult starts from rest),
## and in Sonic 2 it's [code]720[/code] (~12 px/frame).
@export var initial_velocity: float = 0.0:
	set(value):
		initial_velocity = value
		_calculate_launch_velocity()

## Length of the path the catapult goes before launching the player forward.[br]
## In Sonic 3 & Knuckles it's [code]127[/code] (rounded to [code]128[/code] in
## this implementation for convenience), and in Sonic 2 it's [code]384[/code].
@export var path_length: float = 128.0:
	set(value):
		path_length = value
		_calculate_launch_velocity()

## Defines by how many units per second the catapult accelerates
## while it moves forward.[br]
## In Sonic 3 & Knuckles it's [code]3600[/code] (the catapult accelerates
## by 1 px/frame) and in Sonic 2 it's around [code]1536[/code].
@export var acceleration: float = 60.0 * 60.0:
	set(value):
		acceleration = value
		_calculate_launch_velocity()

## Defines by how many units per second the catapult launches the player upwards.[br]
## [b]Note:[/b] The value must be non-negative ([code]vert_launch_velocity >= 0.0[/code]).
@export var vert_launch_velocity: float = 0.0:
	set(value):
		vert_launch_velocity = maxf(0.0, value)
		_calculate_launch_velocity()

## Velocity at which the player is supposed to be launched.[br]
## [b]Note:[/b] DO NOT try to change this variable - its value
## is calculated automatically based on [member initial_velocity],
## [member path_length], [member acceleration], [member vert_launch_velocity]
## and [member direction], and it's there for informational purposes only.
@export var launch_velocity: Vector2 = Vector2.ZERO:
	set(value):
		if _allow_launch_velocity_change:
			launch_velocity = value

## The speed of catapult moving back to the initial position.
@export var retract_speed: float = 60.0 # ~1 px / frame

## Defines if jumping out of the catapult is allowed (original behavior)
## or not (the controls are blocked until the player is launched).
@export var allow_jumping: bool = true

## Defines if horizontal motion is applied to the player when jumping
## out of the catapult (Sonic 3 & Knuckles behavior) or not (Sonic 2 behavior).
@export var jump_imparts_motion: bool = true


# List of affected players
var _players: Array[PlayerChar] = []

# Set to true when the player is attached to the catapult. This is used
# to ignore the collision if the player was colliding with a wall
# starting from the 1'st frame
var _colliding_from_1st_frame: Array[bool] = []

# Is the catapult moving forward?
var _launching: bool = false

# Current velocity the catapult moves forward at
var _velocity: float = 0.0

# Used internally to allow changing the value in `launch_velocity`,
# so the user would be able to see the value of that variable
# in the editor, but wouldn't be able to tamper with it
var _allow_launch_velocity_change: bool = true

# This class is assigned to the $Platform node via `set_script()`,
# so the latter could detect a player colliding with it
# (by having a `physics_collision()` callback)
class _CatapultCollider extends StaticBody2D:
	func physics_collision(body: PlayerChar, _hit_vector: Vector2) -> void:
		get_parent()._player_collision(body)


func _calculate_launch_velocity() -> void:
	_allow_launch_velocity_change = true
	launch_velocity = Vector2(
		(initial_velocity + sqrt(2.0 * acceleration * path_length)) * scale.x,
		-vert_launch_velocity)
	_allow_launch_velocity_change = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# We don't need to display the destination ghost outside of the editor
	$Platform/DestinationGhost.queue_free()
	
	# Set the collider subclass as a script for the moving part of the catapult,
	# so it could catch collision events and initiate launching
	$Platform.set_script(_CatapultCollider)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	var ghost_sprite: Sprite2D = $Platform/DestinationGhost
	ghost_sprite.texture = $Platform/Sprite2D.texture
	ghost_sprite.position.x = path_length
	$Platform/DestinationGhost/Line2D.set_point_position(
		0, Vector2(-path_length + ghost_sprite.texture.get_width() + 2.0, 0.0))

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var platform: StaticBody2D = $Platform
	if _launching:
		var _abort_launch: bool = false
		
		if initial_velocity != 0.0 and platform.position.x == 0.0:
			# Don't add acceleration if the initial velocity is not 0 and this is
			# the 1's frame the catapult is moving forward. That way on the 1'st
			# frame the catapult would move with its initial velocity only
			pass # Do nothing
		else:
			_velocity += acceleration * delta
		
		# Move towards the destination point
		platform.position.x = move_toward(platform.position.x, path_length, _velocity * delta)
		
		# Cache the coordinates for the attachment point before using them
		# in a loop (`$Path` is a shorthand for `get_node("Path")`,
		# and we don't want to call the same function multiple times)
		var attachment_pivot_pos: Vector2 = $Platform/AttachmentPivot.global_position
		
		# Loop through all affected players
		for i: int in _players.size():
			var player = _players[i]
			if player.get_active_gimmick() != self:
				continue
			
			# Set player's position and reset their movement
			var old_position: Vector2 = player.global_position
			player.global_position = attachment_pivot_pos + Vector2(0.0, -(player.get_hitbox().y / 2.0))
			
			# Abort launch and make the catapult go back to its initial position
			# if the player collides with something
			if player.check_for_ceiling() or player.check_for_front_wall() or player.check_for_back_wall():
				# Don't abort if the player was colliding starting from the 1'st frame
				if _colliding_from_1st_frame[i]:
					pass # Do nothing
				else:
					_abort_launch = true
					player.global_position = old_position
			else:
				_colliding_from_1st_frame[i] = false
		
		# If we are at the destination point, then we need to launch
		# all affected players forward.
		# Alternatively, if at least one of the players has collided
		# into something along the way (`_abort_launch == true`),
		# we need to abort the launch.
		if _abort_launch or platform.position.x == path_length:
			# Loop through all affected players
			for player: PlayerChar in _players:
				if player.get_active_gimmick() != self:
					continue
				
				# Detach the player from the catapult
				player.unset_active_gimmick()
				
				# Abort launching and simply set the normal state
				# if any of the players collided with an obstacle
				if _abort_launch:
					player.set_state(PlayerChar.STATES.NORMAL)
					continue
				
				# Launch the player forward
				player.movement = launch_velocity
				player.set_ground_speed(launch_velocity.x)
				player.set_state(PlayerChar.STATES.NORMAL)
				
				# Lock for 15 frames
				player.set_horizontal_lock_timer(15.0 / 60.0)
			
			# Clear player arrays
			_players.clear()
			_colliding_from_1st_frame.clear()
			
			# Unset the launching state, so the catapult
			# can move back to the initial position
			_launching = false
			_abort_launch = false
			
			# Temporarily disable the collision until the platform
			# returns to its initial position
			$Platform/CollisionShape2D.disabled = true
	elif platform.position.x != 0.0:
		# Move toward the initial position
		platform.position.x = move_toward(platform.position.x, 0.0, retract_speed * delta)
		
		# Re-enable the collision if the platform has returned
		# to its initial position
		if platform.position.x == 0.0:
			$Platform/CollisionShape2D.disabled = false

func player_process(player: PlayerChar, _delta : float) -> void:
	# If jumping out is allowed, check if it's player 1 and a jump button is pressed.
	# Don't erase the player from the `_players` array so we can ignore them
	# if they hit the catapult's hitbox again after jumping out
	if allow_jumping and player.playerControl == 1 and player.any_action_pressed():
		player.unset_active_gimmick()
		player.action_jump()
		if jump_imparts_motion:
			player.movement.x = _velocity * scale.x

func player_force_detach_callback(player: PlayerChar) -> void:
	# Remove the player from the array, so the catapult
	# would stop dragging them forward (e.g. when they're hit).
	_players.erase(player)

func _player_collision(player: PlayerChar) -> void:
	# If the player is already in the list, this means they already interacted
	# with the catapult (jumped out and hit its collision box again),
	# so we'll have to ignore them
	if player in _players:
		return
	
	# Detach the player from the current gimmick (if any)
	# or from Tails (if being carried)
	player.force_detach()
	
	# Add player into the list, so the gimmick
	# can enforce their position at every frame
	_players.append(player)

	# Assume the player to be colliding with a wall from the start,
	# so this can be ignored for the first few frames until the player
	# doesn't collide with anything
	_colliding_from_1st_frame.append(true)
	
	# Attach the player to the gimmick
	player.set_direction_signed(scale.x)
	player.get_avatar().get_animator().play(&"idle")
	player.set_state(PlayerChar.STATES.GIMMICK)
	player.set_active_gimmick(self)
	player.movement = Vector2.ZERO
	
	# Check if we aren't in the launching state, so the sound won't play twice
	# if a second player interacts with the catapult while it moves forward
	if not _launching:
		$Platform/Launch.play()
		_launching = true # Set the launching state
		_velocity = initial_velocity
