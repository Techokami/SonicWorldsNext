extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var players = []
var players_phase = []
var players_radius = []

# how many seconds (should be expressed as frames / 60.0) it takes to go around the platofrm
export var spinning_period = 128.0 / 60.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func attach_player(player):
	if players.has(player):
		return
		
	print("attaching player")
	
	player.set_state(player.STATES.ANIMATION)	
	players.append(player)
	
	print("players = ", players)
	
	var player_radius = player.global_position.x - global_position.x
	if (player_radius < 0):
		players_phase.append(PI)
		players_radius.append(abs(player_radius))
		player.animator.play("yRotation")
		player.animator.seek(0.5 * spinning_period)
	else:
		players_phase.append(0)
		players_radius.append(player_radius)
		player.animator.play("yRotation")
		
	player.direction = 1
	player.sprite.flip_h = false
	
	pass

func _process(delta):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	for player in players:
		var index = players.find(player)
		player.direction = 1
		players_phase[index] += (delta / spinning_period) * 2.0 * PI
		player.global_position.x = ceil(global_position.x + players_radius[index] * cos(players_phase[index]))
		player.movement.x = 0
		player.movement.y = 0
#	pass
