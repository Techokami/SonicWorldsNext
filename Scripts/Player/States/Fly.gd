extends PlayerState

# tails flight
var flightTime = 8*60
var flyGrav = 0.03125
var actionPressed = true

var flyHitBox
var carryHitBox
var carryBox

func _ready():
	flyHitBox = parent.get_node("TailsFlightHitArea/HitBox")
	carryHitBox = parent.get_node("TailsCarryBox/HitBox")
	carryBox = parent.get_node("TailsCarryBox")

func state_activated():
	flightTime = 8
	flyGrav = 0.03125
	flyHitBox.disabled = false
	carryHitBox.disabled = false
	actionPressed = true
	
func state_exit():
	flyHitBox.call_deferred("set","disabled",true)
	carryHitBox.call_deferred("set","disabled",true)
	# stop flight sound
	parent.sfx[21].stop()
	parent.sfx[22].stop()
	# delay sound stop, for some reason it bugs out sometimes
	if $FlyBugStop.is_inside_tree():
		$FlyBugStop.start(0.1)

func _process(_delta):
	# Animation
	if parent.water:
		if carryBox.get_player_contacting_count() != 0:
			parent.animator.play("swimCarry")
		elif flightTime > 0:
			parent.animator.play("swim")
		else:
			parent.animator.play("swimTired")
	else:
		if flightTime > 0:
			if carryBox.get_player_contacting_count() == 0:
				parent.animator.play("fly")
			else:
				if parent.movement.y >= 0:
					parent.animator.play("flyCarry")
				else:
					parent.animator.play("flyCarryUP")
		else:
			parent.animator.play("tired")
	
	# flight sound (verify we are not underwater)
	if !parent.water:
		if flightTime > 0:
			if !parent.sfx[21].playing:
				parent.sfx[21].play()
		else:
			if !parent.sfx[22].playing:
				parent.sfx[21].stop()
				parent.sfx[22].play()
	else:
		parent.sfx[21].stop()
		parent.sfx[22].stop()
	

func _physics_process(delta):
	
	# If carrying another player, 
	var carriedPlayer = null
	
	if carryBox.get_player_contacting_count() > 0:
		carriedPlayer = carryBox.get_player(0)

	# Set carried player attributes when there *is* a carried player
	if carriedPlayer != null:
		if carriedPlayer.poleGrabID == carryBox:
			carriedPlayer.movement = parent.movement
			carriedPlayer.stateList[parent.STATES.AIR].lockDir = true
			# set carried player direction
			carriedPlayer.direction = parent.direction
			carriedPlayer.sprite.flip_h = (parent.direction < 0)
		
		# set immediate inputs if ai
		if parent.playerControl == 0:
			for i in range(parent.inputs.size()):
				carriedPlayer.inputMemory[parent.INPUT_MEMORY_LENGTH-1][i] = carriedPlayer.inputs[i]
				parent.inputs[i] = carriedPlayer.inputs[i]
			# Sonic 3 A.I.R. Hybrid Style - convert holding up into continual A presses while in AI mode
			if parent.is_up_held():
				parent.inputs[parent.INPUTS.ACTION] = 1
			carryBox.playerCarryAI = 1
		else:
			carryBox.playerCarryAI = 0
	
	# air movement
	if (parent.get_x_input() != 0):
		
		if (parent.movement.x*parent.get_x_input() < parent.top):
			if (abs(parent.movement.x) < parent.top):
				parent.movement.x = clamp(parent.movement.x+parent.air/GlobalFunctions.div_by_delta(delta)*parent.get_x_input(),-parent.top,parent.top)
				
	# Air drag
	if (parent.movement.y < 0 and parent.movement.y > -parent.releaseJmp*60):
		parent.movement.x -= ((parent.movement.x / 0.125) / 256)*60*delta
	
	# Change parent direction
	if (parent.get_x_input() != 0):
		parent.direction = parent.get_x_input()
		if carriedPlayer != null:
			carriedPlayer.direction = parent.direction
	
	# set facing direction
	parent.sprite.flip_h = (parent.direction < 0)
	
	# Flight logic
	parent.movement.y += flyGrav/GlobalFunctions.div_by_delta(delta)
	
	flightTime -= delta
	# Button press
	if parent.movement.y >= -1*60 and flightTime > 0 and !parent.roof and parent.position.y >= parent.limitTop+16:
		if parent.any_action_held_or_pressed() and (!actionPressed or parent.get_y_input() < 0) and (carryBox.get_player_contacting_count() == 0 or !parent.water):
			flyGrav = -0.125
	# return gravity to normal after velocity is less then -1
	else:
		flyGrav = 0.03125
	
	if parent.position.y < parent.limitTop+16:
		parent.movement.y = max(0,parent.movement.y)
	
	# set actionPressed to prevent input repeats
	actionPressed = parent.any_action_held_or_pressed()
	
	# Reset state if on ground
	if (parent.ground):
		parent.set_state(parent.STATES.NORMAL)


func _on_FlyBugStop_timeout():
	parent.sfx[21].stop()
	parent.sfx[22].stop()
