## Catapult gimmick from Flying Battery Zone.
## Author: Stanislav Gromov
@tool
extends ConnectableGimmick


## Length of the path the catapult goes before releasing the player forward.
@export var path_length: float = 128.0:
	set(value):
		path_length = value
		_calculate_launch_speed()

## Defines by how many units per second the catapult accelerates
## in its launching state.
@export var acceleration: float = 60.0 * 60.0:
	set(value):
		acceleration = value
		_calculate_launch_speed()

## Velocity at which the player is supposed to be launched.[br]
## [b]Note:[/b] This variable is actually immutable and its value
## is calculated automatically based on [member path_length] and
## [member acceleration], and is there for informational purposes only.
@export var launch_speed: float = 0.0:
	set(value):
		if _allow_launch_speed_change:
			launch_speed = value

## The speed of catapult retracting back to the initial position.
@export var retract_speed: float = 60.0 # ~1 px / frame


class _CatapultCollider extends StaticBody2D:
	func physics_collision(body: PlayerChar, _hit_vector: Vector2) -> void:
		get_parent()._player_collision(body)

var _players: Array[PlayerChar] = []
var _launching: bool = false
var _velocity: float = 0.0
var _allow_launch_speed_change: bool = true


func _calculate_launch_speed() -> void:
	_allow_launch_speed_change = true
	launch_speed = sqrt(2.0 * acceleration * path_length)
	_allow_launch_speed_change = false

func _ready() -> void:
	_calculate_launch_speed()
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
		# Add acceleration, but make sure the resulting velocity
		# doesn't exceed the final launch speed
		_velocity = minf(_velocity + (acceleration * delta), launch_speed)
		
		# Move towards the destination point
		platform.position.x = move_toward(platform.position.x, path_length, _velocity * delta)
		
		# If we are at the destination point, then we need
		# to launch all affected players forward
		if platform.position.x == path_length:
			# Unset the launching state, so the catapult can retract
			# back to the initial position
			_launching = false
			
			# Loop through all affected players
			for player: PlayerChar in _players:
				if player.get_active_gimmick() != self:
					continue
				
				# Throw the player forward
				player.unset_active_gimmick()
				player.set_state(PlayerChar.STATES.NORMAL)
				player.movement.x = launch_speed
				
				# Lock for 15 frames
				player.set_horizontal_lock_timer(15.0 / 60.0)
			
			_velocity = 0.0
			_players.clear()
	elif platform.position.x != 0.0:
		# Move toward the initial position
		platform.position.x = move_toward(platform.position.x, 0.0, retract_speed * delta)

func player_physics_process(_player: PlayerChar, _delta: float) -> void:
	# Loop through all affected players
	for player: PlayerChar in _players:
		if player.get_active_gimmick() != self:
			continue
		
		# Set player's position and reset their movement
		player.global_position = $Platform.global_position + Vector2(
			4.0, -(player.get_hitbox().y / 2.0 + $Platform/CollisionShape2D.shape.size.y))

func player_force_detach_callback(player: PlayerChar) -> void:
	# Remove the player from the array, so the catapult
	# would stop dragging them forward (e.g. when they're hit).
	_players.erase(player)

func _player_collision(player: PlayerChar) -> void:
	# Don't interact with any players when
	# retracting back to the initial position
	if not _launching and $Platform.position.x != 0.0:
		return
	
	# Add player into the list, so the gimmick
	# can enforce their position at every frame
	_players.append(player)
	player.set_direction(PlayerChar.DIRECTIONS.RIGHT)
	player.movement = Vector2.ZERO
	player.get_avatar().get_animator().play(&"RESET")
	player.set_state(PlayerChar.STATES.GIMMICK)
	player.set_active_gimmick(self)
	
	# Check if we aren't in the launching state, so the sound won't play twice
	# if a second player interacts with the catapult during launching
	if not _launching:
		$Platform/Launch.play()
		_launching = true # Set the launching state
