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

signal player_entered
signal all_players_exited

func _ready():
	visible = false


func _physics_process(_delta: float) -> void:
	for player: PlayerChar in get_overlapping_bodies():
		# ignore if player is dead or hit
		if player.get_state() == PlayerChar.STATES.DIE or \
			player.get_state() == PlayerChar.STATES.HIT:
			continue
		
		# Ignore if the player is on a gimmick (such as a water bar
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
		var move_dir = Vector2(mod_dir.dot(Vector2(0, player.get_x_input())),
		                       mod_dir.dot(Vector2(player.get_y_input(), 0))
		                      )
		
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
		if current_vector.x > 0.0:
			player.set_direction(PlayerChar.DIRECTIONS.RIGHT)
		else:
			player.set_direction(PlayerChar.DIRECTIONS.LEFT)
		
		# force slide state if the player isn't currently on a gimmick
		if player.get_state() != PlayerChar.STATES.GIMMICK and \
				player.get_active_gimmick() == null:
			player.set_hitbox(player.get_predefined_hitbox(PlayerChar.HITBOXES.HORIZONTAL))
			player.set_state(PlayerChar.STATES.GIMMICK, player.get_predefined_hitbox(PlayerChar.HITBOXES.HORIZONTAL))
			player.get_avatar().get_animator().play("current")


func _on_current_body_entered(body: PlayerChar) -> void:
	body.set_gimmick_var("ActiveCurrent", self)
	player_entered.emit()
	player_count += 1


func _on_current_body_exited(body: PlayerChar) -> void:
	if body.get_gimmick_var("ActiveCurrent") == self:
		body.unset_gimmick_var("ActiveCurrent")
	if normal_state_on_exit and body.get_state() == PlayerChar.STATES.GIMMICK:
		body.set_state(PlayerChar.STATES.NORMAL, body.get_predefined_hitbox(PlayerChar.HITBOXES.HORIZONTAL))
		
	player_count -= 1
	if player_count == 0:
		all_players_exited.emit()
