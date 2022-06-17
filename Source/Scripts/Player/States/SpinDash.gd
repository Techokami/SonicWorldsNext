extends "res://Scripts/Player/State.gd"


#func _input(event):
#	if (parent.playerControl != 0):
#		if (event.is_action_pressed("gm_action")):
#			# reset animation
#			parent.animator.stop()
#			parent.animator.play("spinDash")
#			parent.sprite.frame = 0
#			# play rev sound
#			parent.sfx[2].play()
#			if (parent.spindashPower < 8):
#				parent.spindashPower = min(parent.spindashPower+2,8)
#			parent.sfx[2].pitch_scale = 1.0+((float(parent.spindashPower)/8.0)*0.5)

func state_exit():
	parent.crouchBox.disabled = true
	parent.get_node("HitBox").disabled = false
	
func state_activated():
	parent.crouchBox.disabled = false
	parent.get_node("HitBox").disabled = true
	
func _process(delta):
	
	if parent.inputs[parent.INPUTS.ACTION] == 1:
		# reset animation
		parent.animator.stop()
		parent.animator.play("spinDash")
		# play rev sound
		parent.sfx[2].play()
		if (parent.spindashPower < 8):
			parent.spindashPower = min(parent.spindashPower+2,8)
		parent.sfx[2].pitch_scale = 1.0+((float(parent.spindashPower)/8.0)*0.5)
		
	var dash = parent.sprite.get_node("DashDust")
	dash.visible = !parent.water
	dash.flip_h = parent.sprite.flip_h
	dash.offset.x = abs(dash.offset.x)*sign(-1+int(dash.flip_h)*2)
	
	# release
	if (parent.inputs[parent.INPUTS.YINPUT] <= 0):
		parent.movement.x = (8+(floor(parent.spindashPower) / 2))*60*parent.direction
		parent.sfx[3].play()
		parent.sfx[2].stop()
		parent.sfx[2].pitch_scale = 1
		parent.set_state(parent.STATES.ROLL)
		
		# Lock camera
		parent.lock_camera((parent.spindashPower+8)/60.0)
		
		parent.animator.play("roll")
	parent.spindashPower -= ((parent.spindashPower / 0.125) / (256))*60*delta
		
