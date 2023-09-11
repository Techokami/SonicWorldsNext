extends PlayerState

var dashPower = 12

func _process(delta):
	# dust sprite
	var dash = parent.sprite.get_node("DashDust")
	dash.visible = true
	dash.flip_h = parent.sprite.flip_h
	dash.offset.x = abs(dash.offset.x)*sign(-1+int(dash.flip_h)*2)
	
	# how much power the player has from the peelout
	var speedCalc = parent.spindashPower*60
	
	# increase spindashPower gradually
	parent.spindashPower = min(parent.spindashPower+delta*24,dashPower)
	parent.peelOutCharge = speedCalc
	
	# animation based on speed
	if(speedCalc < 6*60):
		parent.animator.play("walk")
	elif(parent.spindashPower < dashPower):
		parent.animator.play("run")
	else:
		parent.animator.play("peelOut")


	# release
	if (parent.inputs[parent.INPUTS.YINPUT] >= 0):
		# Lock camera
		parent.lock_camera((parent.spindashPower+4)/60.0)
		
		# Release
		parent.movement.x = speedCalc*parent.direction
		parent.sfx[3].play()
		parent.sfx[2].stop()
		parent.set_state(parent.STATES.NORMAL)

func _physics_process(delta):
	# Gravity
	if !parent.ground:
		parent.movement.y += parent.grv/GlobalFunctions.div_by_delta(delta)
