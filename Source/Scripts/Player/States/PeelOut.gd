extends "res://Scripts/Player/State.gd"

var dashPower = 12

func _process(delta):
	var dash = parent.sprite.get_node("DashDust")
	dash.visible = !parent.water
	dash.flip_h = parent.sprite.flip_h
	dash.offset.x = abs(dash.offset.x)*sign(-1+int(dash.flip_h)*2)
	
	var speedCalc = parent.spindashPower*60
	
	
	parent.spindashPower = min(parent.spindashPower+delta*24,dashPower)
	
	# Lock camera
	parent.lock_camera((parent.spindashPower+4)/60.0)
	
	parent.groundSpeed = speedCalc
	
	if(speedCalc < 6*60):
		parent.animator.play("walk")
	elif(parent.spindashPower < dashPower):
		parent.animator.play("run")
	else:
		parent.animator.play("peelOut")
	
	var duration = floor(max(0,8.0-abs(parent.groundSpeed/60)))
	
#	match(parent.animator.current_animation):
#		"walk":
#			duration = floor(max(0,10.0-abs(parent.groundSpeed/60)))
	
	parent.animator.playback_speed = (1.0/(duration+1))*(60/10)

	# release
	if (parent.inputs[parent.INPUTS.YINPUT] >= 0):
		parent.movement.x = speedCalc*parent.direction
		parent.sfx[3].play()
		parent.sfx[2].stop()
		parent.set_state(parent.STATES.NORMAL)
