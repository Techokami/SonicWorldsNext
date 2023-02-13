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

# We want to bring the player back in a little if they are on the extreme overhang of the radius
var max_radius = 30

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
	players_y_offset.append(player.global_position.y - global_position.y)
	
	print("players = ", players)
	
	var player_radius = player.global_position.x - global_position.x
	if (player_radius < 0):
		players_phase.append(PI)
		players_radius.append(min(max_radius, abs(player_radius)))
		player.animator.play("yRotation")
		player.animator.seek(0.5 * spinning_period - .03)
	else:
		players_phase.append(0)
		players_radius.append(min(max_radius, player_radius - .03))
		player.animator.play("yRotation")
		
	player.direction = 1
	player.sprite.flip_h = false
	
	# XXX Need to find a way to prevent the player from getting pushed up when
	# clipping against walls while on this thing
	#player.translate = true
	
	pass
func detachPlayer(player, index):
	players.remove(index)
	players_phase.remove(index)
	players_radius.remove(index)
	players_y_offset.remove(index)
	# XXX Need to find a way to prevent the player from getting pushed up when
	# clipping against walls while on this thing
	#if player.currentState != player.STATES.DIE:
		#player.translate = false

func _process(delta):
	for player in players:
		var index = players.find(player)
		if player.inputs[player.INPUTS.ACTION] == 1:
			detachPlayer(player, index)
			# Whoa, jump!
			player.action_jump("roll", true, false)
			
		if player.currentState != player.STATES.ANIMATION:
			detachPlayer(player, index)
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	for player in players:
		var index = players.find(player)
		player.direction = 1
		players_phase[index] += (delta / spinning_period) * 2.0 * PI
		player.global_position.x = ceil(global_position.x + players_radius[index] * cos(players_phase[index]))
		player.global_position.y = global_position.y + players_y_offset[index]
		player.movement.x = 0
		player.movement.y = 0
		player.cam_update()
