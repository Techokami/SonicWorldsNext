extends Node

# Vertical Swinging Bar from Mushroom Hill Zone
# Author: DimensionWarped

# Sound to play when the bar is grabbed
export var grabSound = preload("res://Audio/SFX/Player/Grab.wav")

# How many times to spin around the bar before launching
export var rotations = 1

# How fast the player needs to be going to catch the bar
export var grabSpeed = 300

# How fast to launch the player if the mode is constant
export var launchSpeed = 720

# How fast to launch the player if the mode is multiply
export var launchMultiplier = 1.5

# Maximum speed to allow the player to launch when in multiply
export var launchMultiMaxSpeed = 900

# The CONSTANT launch mode will always launch the player with a set speed based on launchSpeed
# The MULTIPLY launch mode will launch the player at a multiple of their incoming velocity clamped
#              to a given max value.
enum {CONSTANT, MULTIPLY}
export(int, "constant", "multiply") var launchMode # Keep these in the same order as the above enum

var players = [] # Tracks the players that are active within the gimmick
var players_speed = [] # Tracks the player's speed on entering the loop (used for multiply mode)
var players_cur_loops = [] # Tracks how many loops the player has been throught eh animation
var players_pass_hit = [] # Tracks whether the player has hit the release point of the animation

# Once cur_loops reaches the number of rotations defined for the object, release

var last_frame = 0
var pass_hit = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$Grab.stream = grabSound
	pass # Replace with function body.
	
func _physics_process(_delta):
	
	# Iterate through every player to see if they should be mounted to the bar
	for i in players:
		var playerIndex = players.find(i)
		if !(check_grab(i)):
			continue
			
		if players_speed[playerIndex] == null:

				
			# Stores the player's speed when hitting the bar so we can unleash it later.
			players_speed[playerIndex] = i.groundSpeed
			players_cur_loops[playerIndex] = 0
			players_pass_hit[playerIndex] = false
			
			# Reset the player's direction to their direction of travel so that they don't mount
			# the bar backwards if they are facing against their direction of travel.
			if (i.groundSpeed > 0):
				i.direction = 1
			else:
				i.direction = -1
				
			i.sprite.flip_h = (i.direction < 0)
				
			$Grab.play()
			if (i.direction > 0):
				i.animator.play("grabVerticalBar")
			else:
				i.animator.play("grabVerticalBarOffset")
			
			i.set_state(i.STATES.SWINGVERTICALBAR)

			
			# Drop all the speed values to 0 to prevent issues.
			i.groundSpeed = 0
			i.movement.x = 0
			i.movement.y = 0
			i.cam_update()
	
	var number = 0
	for i in players:
		if i.currentState == i.STATES.SWINGVERTICALBAR:
			i.global_position.x = get_parent().get_global_position().x
			number += 1
		
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for i in players:
		# If the player isn't on the bar, skip it.
		if i.currentState != i.STATES.SWINGVERTICALBAR:
			continue
			
		var playerIndex = players.find(i)
		
		# We don't start tracking rotation and stuff if the player hasn't gotten out of grabVerticalBar/Offset
		# Switch the player out of the grab animation pretty much immediately.
		var anim = i.animator.get_current_animation()
		if (anim == "grabVerticalBar" or anim == "grabVerticalBarOffset"):
			continue
		
		# Real code -- release the player after they hit the desired number of loops through the animation
		if (!players_pass_hit[playerIndex]):
			if (i.animator.get_current_animation_position() >= i.animator.get_current_animation_length() * 0.95):
				players_pass_hit[playerIndex] = true
				players_cur_loops[playerIndex] += 1
				if (players_cur_loops[playerIndex] >= rotations):
					if launchMode == MULTIPLY:
						print("launch mode multiply")
						i.movement.x = min(launchMultiMaxSpeed, max(-launchMultiMaxSpeed, players_speed[playerIndex] * launchMultiplier))
					else:
						print("launch mode constant")
						i.movement.x = launchSpeed * i.direction
					i.set_state(i.STATES.NORMAL)
					i.movement.y = 0
		else:
			if (i.animator.get_current_animation_position() < i.animator.get_current_animation_length() * 0.25):
				players_pass_hit[playerIndex] = false
			
	pass

func check_grab(body):
	# Only grab the bar if the player is in a ground state (rolling or running) and speed is above value
	if !(body.ground):
		return false
		
	# Skip if already on the vertical bar or player is jumping
	if (body.currentState == body.STATES.SWINGVERTICALBAR or body.currentState == body.STATES.JUMP):
		return false
		
	if abs(body.groundSpeed) > grabSpeed:
		return true
		
	return false
	
func _on_VerticalBarArea_body_entered(body):
	if body != get_parent(): #check that parent isn't going to be carried
		if !players.has(body):
			players.append(body)
			players_speed.resize(players.size())
			players_cur_loops.resize(players.size())
			players_pass_hit.resize(players.size())

func _on_VerticalBarArea_body_exited(body):
	remove_player(body)
	
func remove_player(player):
	if players.has(player):
		# Don't allow removal of someone who is still on the vertical bar. This can occur with
		# high speeds. Preventing this should be fine since the player will be brought back into
		# collision overlap range by virtue of being on the bar.
		if (player.currentState == player.STATES.SWINGVERTICALBAR):
			return
			
		# remove player from contact point
		var getIndex = players.find(player)
		players.erase(player)
		players_speed.remove(getIndex)
		players_cur_loops.remove(getIndex)
		players_pass_hit.remove(getIndex)
