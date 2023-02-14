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

var players_y_offset = []

# array of players z levels upon interacting with the gimmick. The Z level is offset
# by the player's phase while on the gimmick, this is so we can restore it when they
# detach
var players_z_level = []

# We want to bring the player back in a little if they are on the extreme overhang of the radius
var max_radius = 30

# The animation offset makes it so that you aren't exactly synchronized with the
# rotation around the barrel. The default value advances the animation by 0.03
# seconds to try to closely synchronize the camera facing frame with where it would
# pop up if you were on the actual barrel from CNZ
var animation_offset = -0.02

# how many seconds (should be expressed as frames / 60.0) it takes to go around the platform
# Note that this is the same as the number of frames in the yRotation animation and changing
# this will mean throwing off a bunch of stuff.
var spinning_period = 128.0 / 60.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func attach_player(player):
	if players.has(player):
		return

	player.set_state(player.STATES.ANIMATION)	
	players.append(player)
	players_y_offset.append(player.global_position.y - global_position.y)
	players_z_level.append(player.get_z_index())

	var player_radius = player.global_position.x - global_position.x
	if (player_radius < 0):
		players_phase.append(PI)
		players_radius.append(min(max_radius, abs(player_radius)))
		player.animator.play("yRotation")
		player.animator.seek(0.5 * spinning_period + animation_offset)
	else:
		players_phase.append(0)
		players_radius.append(min(max_radius, player_radius))
		player.animator.play("yRotation")
		player.animator.seek(animation_offset)

	player.direction = 1
	player.sprite.flip_h = false

	# Prevents player from clipping on walls while they are on the fringes of the gimmick
	player.translate = true

	pass
func detach_player(player, index):
	
	players.remove(index)
	players_phase.remove(index)
	players_radius.remove(index)
	players_y_offset.remove(index)
	player.set_z_index(players_z_level[index])
	players_z_level.remove(index)
	
	# XXX Need to do something about wall overlap possibility on detach
	
	if player.currentState != player.STATES.DIE:
		player.translate = false

func _process(delta):
	for player in players:
		var index = players.find(player)
		
		# Ok, this is clever.
		# If the player is closer to the center, the influence of their phase is diminished.
		player.set_z_index(get_z_index() + 2 * players_radius[index] * -sin(players_phase[index]))
			
		if player.inputs[player.INPUTS.ACTION] == 1:
			detach_player(player, index)
			# Whoa, jump!
			player.action_jump("roll", true, false)
			continue
			
		if player.currentState != player.STATES.ANIMATION:
			detach_player(player, index)

# Called every frame. 'delta' is the elapsed time since the previous frame.
var skipFrames = 0
func _physics_process(delta):
	for player in players:
		var index = players.find(player)
		player.direction = 1
		players_phase[index] += (delta / spinning_period) * 2.0 * PI
		player.global_position.x = ceil(global_position.x + players_radius[index] * cos(players_phase[index]))
		player.global_position.y = global_position.y + players_y_offset[index]
		player.movement.x = 0
		player.movement.y = 0
		player.update()
		player.cam_update()
