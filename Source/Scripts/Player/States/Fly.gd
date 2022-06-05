extends "res://Scripts/Player/State.gd"

var flightTime = 8*60
var flyGrav = 0.03125
var actionPressed = true

func state_activated():
	flightTime = 8
	flyGrav = 0.03125
	actionPressed = true
	
func state_exit():
	# stop flight sound
	parent.sfx[21].stop()
	parent.sfx[22].stop()

func _process(delta):
	# Animation
	if parent.water:
		if flightTime > 0:
			parent.animator.play("swim")
		else:
			parent.animator.play("swimTired")
	else:
		if flightTime > 0:
			parent.animator.play("fly")
		else:
			parent.animator.play("tired")
	
	# flight sound
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
	# air movement
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		
		if (parent.movement.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (abs(parent.movement.x) < parent.top):
				parent.movement.x = clamp(parent.movement.x+parent.air/delta*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top)
				
	# Air drag
	if (parent.movement.y < 0 and parent.movement.y > -parent.releaseJmp*60):
		parent.movement.x -= ((parent.movement.x / 0.125) / 256)*60*delta
	
	# Change parent direction
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		parent.direction = parent.inputs[parent.INPUTS.XINPUT]
	
	# set facing direction
	parent.sprite.flip_h = (parent.direction < 0)
	
	# Flight logic
	parent.movement.y += flyGrav/delta
	
	flightTime -= delta
	# Button press
	if parent.movement.y >= -1*60 and flightTime > 0 and !parent.roof and parent.position.y >= parent.limitTop+16:
		if parent.inputs[parent.INPUTS.ACTION] and !actionPressed:
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
