extends "res://Scripts/Player/State.gd"

var flightTime = 8*60
var flyGrav = 0.03125
var actionPressed = true

onready var flyHitBox = parent.get_node("TailsFlightHitArea/HitBox")
onready var carryHitBox = parent.get_node("TailsCarryBox/HitBox")
onready var carryBox = parent.get_node("TailsCarryBox")


func state_activated():
	flightTime = 8
	flyGrav = 0.03125
	actionPressed = true
	flyHitBox.disabled = false
	carryHitBox.disabled = false
	
func state_exit():
	flyHitBox.disabled = true
	carryHitBox.disabled = true
	# stop flight sound
	parent.sfx[21].stop()
	parent.sfx[22].stop()
	# delay sound stop, for some reason it bugs out sometimes
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	parent.sfx[21].stop()
	parent.sfx[22].stop()

func _process(_delta):
	# Animation
	if parent.water:
		if carryBox.playerContacts != 0:
			parent.animator.play("swimCarry")
		elif flightTime > 0:
			parent.animator.play("swim")
		else:
			parent.animator.play("swimTired")
	else:
		if flightTime > 0:
			if carryBox.playerContacts == 0:
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
	
	# Carrying other palyer
	var carryPlayer = null
	
	if carryBox.playerContacts > 0:
		carryPlayer = carryBox.players[0]
		if carryPlayer.poleGrabID == carryBox:
			carryPlayer.movement = parent.movement
			carryPlayer.stateList[parent.STATES.AIR].lockDir = true
			# set carried player direction
			carryPlayer.direction = parent.direction
			carryPlayer.sprite.flip_h = (parent.direction < 0)
		
		# set immediate inputs if ai
		if parent.playerControl == 0:
			for i in range(parent.inputs.size()):
				carryBox.players[0].inputMemory[parent.INPUT_MEMORY_LENGTH-1][i] = carryBox.players[0].inputs[i]
				parent.inputs[i] = carryBox.players[0].inputs[i]
	
	# air movement
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		
		if (parent.movement.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (abs(parent.movement.x) < parent.top):
				parent.movement.x = clamp(parent.movement.x+parent.air/GlobalFunctions.div_by_delta(delta)*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top)
				
	# Air drag
	if (parent.movement.y < 0 and parent.movement.y > -parent.releaseJmp*60):
		parent.movement.x -= ((parent.movement.x / 0.125) / 256)*60*delta
	
	# Change parent direction
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		parent.direction = parent.inputs[parent.INPUTS.XINPUT]
		if carryPlayer != null:
			carryPlayer.direction = parent.direction
	
	
	# set facing direction
	parent.sprite.flip_h = (parent.direction < 0)
	
	# Flight logic
	parent.movement.y += flyGrav/GlobalFunctions.div_by_delta(delta)
	
	flightTime -= delta
	# Button press
	if parent.movement.y >= -1*60 and flightTime > 0 and !parent.roof and parent.position.y >= parent.limitTop+16:
		if parent.inputs[parent.INPUTS.ACTION] and !actionPressed and (carryBox.playerContacts == 0 or !parent.water):
			flyGrav = -0.125
	# return gravity to normal after velocity is less then -1
	else:
		flyGrav = 0.03125
	
	if parent.position.y < parent.limitTop+16:
		parent.movement.y = max(0,parent.movement.y)
	
	# set actionPressed to prevent input repeats
	actionPressed = parent.inputs[parent.INPUTS.ACTION]
	# Reset state if on ground
	if (parent.ground):
		parent.set_state(parent.STATES.NORMAL)
