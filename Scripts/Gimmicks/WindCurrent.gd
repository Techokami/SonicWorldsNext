extends Area2D

var players = []
@export var speed = 400.0 # default power
@export var canMove = true
@export var moveSpeed = 200.0 # player movement power

signal player_entered
signal all_players_exited

func _ready():
	visible = false

func _physics_process(_delta):
	# if any players are found in the array, if they're on the ground make them roll
	if players.size() > 0:
		for i in players:
			# ignore if player is dead
			if i.currentState == i.STATES.DIE:
				break
			# determine the direction of the arrow based on scale and rotation
			var getDir = Vector2.RIGHT.rotated(global_rotation)
			
			# disconect floor
			if i.ground:
				i.disconnect_from_floor()
			
			# set movement
			# calculate movement direction
			var rotDir = getDir.rotated(deg_to_rad(90)).abs()
			var moveDir = Vector2(rotDir.dot(Vector2(i.inputs[i.INPUTS.XINPUT],0)),rotDir.dot(Vector2(0,i.inputs[i.INPUTS.YINPUT])))
			i.movement = (getDir*speed)+(moveDir*moveSpeed)
			
			# move against slopes
			if i.roof:
				# check for collision
				i.verticalSensorLeft.target_position *= 2
				i.verticalSensorRight.target_position *= 2
				var slope = i.get_nearest_vertical_sensor()
				if slope != null:
					# slide along slope normal
					i.movement.x = i.movement.slide(slope.get_collision_normal()).x
			# push vertically against ceiling and floors
			if i.has_method("push_vertical"):
				i.push_vertical()

			# force player direction
			if getDir.x != 0:
				i.direction = getDir.x
				# set flipping on sprite
				i.sprite.flip_h = (i.direction < 0)
			
			# force slide state
			if i.currentState != i.STATES.ANIMATION or i.animator.current_animation != "current":
				# check that specific animations aren't playing (related to under water bars)
				if i.animator.current_animation != "clingVerticalBar" and i.animator.current_animation != "clingVerticalBarOffset":
					i.set_state(i.STATES.ANIMATION,i.currentHitbox.ROLL)
					i.animator.play("current")

func _on_WindCurrent_body_entered(body):
	if !players.has(body):
		# emit signal for player touches (can be used for giant fans)
		if players.size() == 0:
			player_entered.emit()
		players.append(body)


func _on_WindCurrent_body_exited(body):
	if players.has(body):
		# check that player is not dead
		if body.currentState != body.STATES.DIE:
			body.set_state(body.STATES.NORMAL)
		players.erase(body)
		# emit signal for players exiting (can be used for giant fans)
		if players.size() == 0:
			all_players_exited.emit()
