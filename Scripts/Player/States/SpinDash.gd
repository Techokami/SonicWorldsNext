extends PlayerState


func state_exit():
	parent.get_node("HitBox").shape.size = parent.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL)


func state_activated():
	parent.get_node("HitBox").position = parent.hitBoxOffset.crouch


func state_process(delta: float) -> void:
	var animator: PlayerCharAnimationPlayer = parent.get_avatar().get_animator()
	# Charging up (if your character does something different for button 2 or 3 you'll want to adjust this)
	if parent.inputs[parent.INPUTS.ACTION] == 1 or parent.inputs[parent.INPUTS.ACTION2] == 1 or parent.inputs[parent.INPUTS.ACTION3] == 1:
		# reset animation
		animator.stop()
		animator.play("spinDash")
		# play rev sound
		parent.sfx[2].play()
		# increase dash power
		if (parent.spindashPower < 8):
			parent.spindashPower = min(parent.spindashPower+2,8)
		parent.sfx[2].pitch_scale = 1.0+((float(parent.spindashPower)/8.0)*0.5)
	
	# dust sprite
	var dash = parent.sprite.get_node("DashDust")
	dash.visible = true
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
		parent.camera.lock((parent.spindashPower+8.0)/60.0)
		
		animator.play("roll")
	
	# decrease the dash power for next frame
	parent.spindashPower -= ((parent.spindashPower / 0.125) / (256))*60*delta

## Physics function that the player invokes while this state is active
## Override this when creating your state if you need this funcitonality
func state_physics_process(_delta: float) -> void:
	# Gravity
	if !parent.ground:
		parent.set_state(parent.STATES.AIR)
