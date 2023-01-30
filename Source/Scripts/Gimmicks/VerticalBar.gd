extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Sound to play when the bar is grabbed
export var grabSound = preload("res://Audio/SFX/Player/Grab.wav")

# How many times to spin around the bar before launching
export var rotations = 1

# How fast the player needs to be going to catch the bar
export var grabSpeed = 300

# How much to multiply the speed when launching off the bar
export var speedMultiplier = 1.25

var players = []
var players_speed = []

# Called when the node enters the scene tree for the first time.
func _ready():
	$Grab.stream = grabSound
	pass # Replace with function body.
	
func _physics_process(_delta):
	
	# Iterate through every player to see if they should be mounted to the bar
	for i in players:
		var playID = players.find(i)
		if !(check_grab(i,playID)):
			continue
			
		if players_speed[playID] == null:
			$Grab.play()
			if (i.direction > 0):
				i.animator.play("swingVerticalBar")
			else:
				i.animator.play("swingVerticalBarOffset")
			
			i.set_state(i.STATES.SWINGVERTICALBAR)
			i.poleGrabID = self # I guess we can repurpose this since it's similar...
			players_speed[playID] = i.groundSpeed
			
		# XXX Probably need to lock position to bar here
		i.cam_update()
		
		# lock player direction
		i.stateList[i.STATES.AIR].lockDir = true
	
	var number = 0
	for i in players:
		if i.currentState == i.STATES.SWINGVERTICALBAR:
			i.global_position.x = get_parent().get_global_position().x
			number += 1
			print("cur number is", number)
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# check for player inputs
	pass

func check_grab(body, playID):
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

func _on_VerticalBarArea_body_exited(body):
	remove_player(body)
	
func remove_player(player):
	if players.has(player):
	# remove player from contact point
		var getIndex = players.find(player)
		players.erase(player)
		players_speed.remove(getIndex)
