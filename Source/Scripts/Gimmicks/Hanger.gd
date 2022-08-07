extends Area2D

# playerID array and contact position
var players = []
var contactPoint = []
var playerContacts = 0
var contactDistance = 17

export var holdDownToDrop = false
export var setCenter = false
export var onlyActiveMovingDown = true
export var lockPlayerDirection = true
export var grabSound = preload("res://Audio/SFX/Player/Grab.wav")

func _ready():
	$Grab.stream = grabSound

func _physics_process(delta):
	playerContacts = 0
	for i in players:
		var playID = players.find(i)
		# verify state is valid for grabbing and not on floor
		if !i.ground and (i.currentState == i.STATES.AIR or i.currentState == i.STATES.JUMP or i.currentState == i.STATES.GLIDE):
			# check settings if to connect with hanger (mainly vertical momentum being downard)
			if check_grab(i,playID):
				playerContacts += 1
				# jump and air states don't change animation so set it to hanging
				i.animator.play("hang")
				i.set_state(i.STATES.AIR)
				
				# set contact point (start grab)
				if contactPoint[playID] == null:
					$Grab.play()
					i.poleGrabID = self
					var calcDistance = contactDistance+(19-i.currentHitbox.NORMAL.y)
					if !setCenter:
						contactPoint[playID] = Vector2(i.global_position.x-global_position.x,calcDistance)
					else:
						contactPoint[playID] = Vector2(0,calcDistance)
				
				var getPose = (global_position+contactPoint[playID].rotated(rotation)).round()
				# verify position change won't clip into objects
				if !i.test_move(i.global_transform,getPose-i.global_position):
					i.global_position = getPose
					i.movement = Vector2.ZERO
				
				i.cam_update()
				# lock player direction
				if lockPlayerDirection:
					i.stateList[i.STATES.AIR].lockDir = true
		else:
			if i.poleGrabID == self:
				i.poleGrabID = null
			contactPoint[playID] = null
			if lockPlayerDirection:
				i.stateList[i.STATES.AIR].lockDir = false

func _process(delta):
	# check for player inputs
	for i in players:
		# verify state is valid for grabbing and not on floor
		if !i.ground and (i.currentState == i.STATES.AIR or i.currentState == i.STATES.JUMP):
			var playID = players.find(i)
			if check_grab(i,playID):
				if i.inputs[i.INPUTS.ACTION] == 1 and (!holdDownToDrop or i.inputs[i.INPUTS.YINPUT] > 0):
					# set animation to roll
					i.animator.play("roll")
					# jump off
					i.set_state(i.STATES.JUMP)
					i.movement.y = -i.jmp/2
					# set ground speed to 0 to stop rolling going nuts
					i.groundSpeed = 0
					i.poleGrabID = null
					contactPoint[playID] = null
					playerContacts -= 1

func check_grab(body, playID):
	return (
		(body.poleGrabID == null or body.poleGrabID == self)
		and ((body.movement.y >= 0 or !onlyActiveMovingDown) 
		and body.global_position.y >= (global_position+Vector2(0,contactDistance).rotated(rotation)).y
		and (!holdDownToDrop or body.inputs[body.INPUTS.YINPUT] <= 0) or contactPoint[playID] != null)
		)

func _on_Hanger_body_entered(body):
	if body != get_parent(): #check that parent isn't going to be carried
		if !players.has(body):
			players.append(body)
			contactPoint.resize(players.size())
			contactPoint[players.size()-1] = null


func _on_Hanger_body_exited(body):
	remove_player(body)

func remove_player(player):
	if players.has(player):
		# remove player from contact point
		var getIndex = players.find(player)
		contactPoint.remove(getIndex)
		
		players.erase(player)
		playerContacts = players.size()
