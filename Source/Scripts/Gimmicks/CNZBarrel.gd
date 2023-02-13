extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# contains currently attached players.
var players = []
# contains the phase (their movement around the barrel) - accumulated with relation to
# spinning_period during the physics_process.
var players_phase = []
# Depending on where you initially connect to the gimmick, your radius is set based
# on how far you were from the center of the barrel.
var players_radius = []

# The animation offset makes it so that you aren't exactly synchronized with the
# rotation around the barrel. The default value advances the animation by 0.03
# seconds to try to closely synchronize the camera facing frame with where it would
# pop up if you were on the actual barrel from CNZ
var animation_offset = 0.03

# how many seconds (should be expressed as frames / 60.0) it takes to go around the platform
# Note that this is the same as the number of frames in the yRotation animation and changing
# this will mean throwing off a bunch of stuff. Don't even know why I made it exortable just
# yet.
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
		player.animator.seek(0.5 * spinning_period - .03)
	else:
		players_phase.append(0)
		players_radius.append(player_radius - .03)
		player.animator.play("yRotation")
		
	player.direction = 1
	player.sprite.flip_h = false
	
	pass

func _process(delta):
	for player in players:
		if player.inputs[player.INPUTS.ACTION] == 1:
			var index = players.find(player)
			players.remove(index)
			players_phase.remove(index)
			players_radius.remove(index)
			# Whoa, jump!
			player.action_jump("roll", true, false)
		pass
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
		player.cam_update()
