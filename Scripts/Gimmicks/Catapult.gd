## Catapult gimmick from Flying Battery Zone.[br]
## Author: Stanislav Gromov (with help and guidance from DimensionWarped).
@tool
class_name Catapult extends ConnectableGimmick


## Length of the path the catapult goes before releasing the player forward.
@export var path_length: float = 128.0:
	set(value):
		path_length = value
		_calculate_launch_velocity()

## Defines by how many units per second the catapult accelerates
## in its launching state.
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
## [b]Note:[/b] This variable is actually immutable and its value
## is calculated automatically based on [member path_length] and
## [member acceleration], and is there for informational purposes only.
@export var launch_velocity: Vector2 = Vector2.ZERO:
	set(value):
		if _allow_launch_velocity_change:
			launch_velocity = value

## The speed of catapult moving back to the initial position.
@export var retract_speed: float = 60.0 # ~1 px / frame

## Defines if jumping out of the gimmick is allowed (Sonic 2 behavior)
## or not (the controls are blocked until the player is launched, a-la Sonic 3).
@export var allow_jumping_out: bool = false


class _CatapultCollider extends StaticBody2D:
	func physics_collision(body: PlayerChar, _hit_vector: Vector2) -> void:
		get_parent()._player_collision(body)

var _players: Array[PlayerChar] = []
var _launching: bool = false
var _abort_launch: bool = false
var _velocity: float = 0.0
var _allow_launch_velocity_change: bool = true


func _calculate_launch_velocity() -> void:
	_allow_launch_velocity_change = true
	launch_velocity = Vector2(sqrt(2.0 * acceleration * path_length), -vert_launch_velocity)
	_allow_launch_velocity_change = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# Set the collider subclass as a script for the moving part of the catapult,
	# so it could catch collision events and initiate launching
	$Platform.set_script(_CatapultCollider)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var platform: StaticBody2D = $Platform
	if _launching:
		if not _abort_launch:
			# Add acceleration, but make sure the resulting velocity
			# doesn't exceed the final launch speed
			_velocity = minf(_velocity + (acceleration * delta), launch_velocity.x)
			
			# Move towards the destination point
			platform.position.x = move_toward(platform.position.x, path_length, _velocity * delta)
		
		# If we are at the destination point, then we need
		# to launch all affected players forward
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
					
				# Throw the player forward
				player.movement = launch_velocity
				if vert_launch_velocity == 0.0:
					player.set_state(PlayerChar.STATES.NORMAL)
				else:
					player.disconnect_from_floor()
					player.set_state(PlayerChar.STATES.AIR)
				
				# Lock for 15 frames
				player.set_horizontal_lock_timer(15.0 / 60.0)
			
			# Unset the launching state, so the catapult
			# can move back to the initial position
			_launching = false
			_abort_launch = false
			_velocity = 0.0
			_players.clear()
			$Platform/CollisionShape2D.disabled = true
	elif platform.position.x != 0.0:
		# Move toward the initial position
		platform.position.x = move_toward(platform.position.x, 0.0, retract_speed * delta)
		if platform.position.x == 0.0:
			$Platform/CollisionShape2D.disabled = false

func player_physics_process(player: PlayerChar, _delta: float) -> void:
	# Set player's position and reset their movement
	var old_position: Vector2 = player.global_position
	player.global_position = $Platform.global_position + Vector2(
		4.0, -(player.get_hitbox().y / 2.0 + $Platform/CollisionShape2D.shape.size.y))
	
	# Abort launch and make the catapult go back to its initial position
	# if the player collides with something
	if player.check_for_ceiling() or player.check_for_front_wall() or player.check_for_back_wall():
		_abort_launch = true
		player.global_position = old_position
	
	# If jumping out is allowed, check if it's player 1 and a jump button is pressed
	if allow_jumping_out and player.playerControl == 1 and player.any_action_pressed():
		_players.erase(player)
		player.unset_active_gimmick()
		player.action_jump()
		player.movement.x = _velocity

func player_force_detach_callback(player: PlayerChar) -> void:
	# Remove the player from the array, so the catapult
	# would stop dragging them forward (e.g. when they're hit).
	_players.erase(player)

func _player_collision(player: PlayerChar) -> void:
	# Don't interact with any players when moving back to the initial position
	if not _launching and $Platform.position.x != 0.0:
		return
	
	# Add player into the list, so the gimmick
	# can enforce their position at every frame
	_players.append(player)
	
	# Detach the player from the current gimmick (if any)
	# or from Tails (if being carried)
	player.force_detach()
	
	# Attach the player to the gimmick
	player.set_direction(PlayerChar.DIRECTIONS.RIGHT)
	player.get_avatar().get_animator().play(&"idle")
	player.set_state(PlayerChar.STATES.GIMMICK)
	player.set_active_gimmick(self)
	player.movement = Vector2.ZERO
	
	# Check if we aren't in the launching state, so the sound won't play twice
	# if a second player interacts with the catapult during launching
	if not _launching:
		$Platform/Launch.play()
		_launching = true # Set the launching state
