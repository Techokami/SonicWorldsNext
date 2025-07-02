extends Area2D

## Force that the current pushes the player at (note - gravity is disabled while in current)
@export var current_vector = Vector2(400.0, -7.0) # default power

## How fast the player can move up and down
@export var move_speed = 150.0 # player movement power

## If set to true, player will transition to the normal state on exiting (animation stays the same)
## If set to false, player will remain in GIMMICK state and is subject to floating until freed
## by something else.
@export var normal_state_on_exit = true

var player_count = 0

# this isn't the same as player_count, because if the parent object is a fan,
# the variable is only set to true after waiting for the fan to start working
@export var activated: bool = true

var players: Array[PlayerChar] = []

signal player_entered
signal all_players_exited


func _ready():
	visible = false

func _physics_process(_delta: float) -> void:
	# skip if the wind current isn't activated yet
	if not activated:
		return
	
	for player: PlayerChar in players:
		# ignore if player is dead or hit
		match player.get_state():
			PlayerChar.STATES.DIE, PlayerChar.STATES.HIT:
				continue
		
		# Ignore if the player is on a gimmick (such as a water bar)
		if player.get_active_gimmick() != null:
			continue
			
		# disconect floor
		if player.is_on_ground():
			player.disconnect_from_floor()
		
		# set movement
		# calculate movement direction
		# The current direction is normalized and we use abs. Normalization is so that the impact
		# of the player's movement is always just based on move_speed without influence from the
		# strength of the current. Abs is because we want left/right and up/down not to get inverted
		# if the current is going left or upwards.
		var mod_dir = current_vector.normalized().abs()
		
		# Linear algebra is scary, but this basically just makes it so that if the current is moving
		# right, then up/down motion works and if the current is moving up, left/right movement works...
		# Then for everything in between, you get a mix of both.
		var move_dir = Vector2(
			mod_dir.dot(Vector2(0, player.get_x_input())),
			mod_dir.dot(Vector2(player.get_y_input(), 0)))
		
		player.movement = current_vector+(move_dir*move_speed)
		
		# move against slopes
		if player.roof:
			# check for collision
			player.verticalSensorLeft.target_position *= 2
			player.verticalSensorRight.target_position *= 2
			var slope = player.get_nearest_vertical_sensor()
			if slope != null:
				# slide along slope normal
				player.movement.x = player.movement.slide(slope.get_collision_normal()).x
		
		# push vertically against ceiling and floors
		player.push_vertical()
		
		# force player direction
		player.set_direction(PlayerChar.DIRECTIONS.RIGHT if current_vector.x > 0.0 else PlayerChar.DIRECTIONS.LEFT)
		
		# force slide state if the player isn't currently on a gimmick
		if player.get_state() != PlayerChar.STATES.GIMMICK and \
				player.get_active_gimmick() == null:
			player.set_hitbox(player.get_predefined_hitbox(PlayerChar.HITBOXES.HORIZONTAL))
			player.set_state(PlayerChar.STATES.GIMMICK, player.get_predefined_hitbox(PlayerChar.HITBOXES.HORIZONTAL))
			player.get_avatar().get_animator().play("current")

func _add_player(player: PlayerChar) -> void:
	if player in players:
		return

	players.append(player)
	player.set_gimmick_var("ActiveCurrent", self)
	player_entered.emit()
	player_count += 1

func _remove_player(player: PlayerChar) -> void:
	if not player in players:
		return

	players.erase(player)
	if player.get_gimmick_var("ActiveCurrent") == self:
		player.unset_gimmick_var("ActiveCurrent")
	if normal_state_on_exit and player.get_state() == PlayerChar.STATES.GIMMICK:
		player.set_state(PlayerChar.STATES.NORMAL, player.get_predefined_hitbox(PlayerChar.HITBOXES.HORIZONTAL))

	player_count -= 1
	if player_count == 0:
		all_players_exited.emit()


func _on_current_body_entered(body: PlayerChar) -> void:
	_add_player(body)

func _on_current_body_exited(body: PlayerChar) -> void:
	_remove_player(body)

func activate() -> void:
	if activated:
		return

	activated = true
	for player: PlayerChar in get_overlapping_bodies():
		_add_player(player)

func deactivate() -> void:
	if not activated:
		return

	activated = false
	for player: PlayerChar in players:
		_remove_player(player)
