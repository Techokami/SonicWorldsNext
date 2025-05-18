extends PlayerState

func state_process(_delta: float) -> void:
	# jumping off
	if parent.inputs[parent.INPUTS.ACTION] == 1 or parent.inputs[parent.INPUTS.ACTION2] == 1 or parent.inputs[parent.INPUTS.ACTION3] == 1:
		parent.action_jump()
	
	# if offset, flip around
	if parent.get_avatar().get_animator().current_animation == "corkScrewOffset":
		parent.sprite.flip_v = true
		parent.sprite.offset.y = 4


func state_physics_process(delta: float) -> void:
	# gravity
	parent.movement.y += parent.grv/GlobalFunctions.div_by_delta(delta)
	
	# determine flip based on the direction
	parent.sprite.flip_h = (parent.direction < 0)
	
	# movement
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		if (parent.movement.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (sign(parent.movement.x) == parent.inputs[parent.INPUTS.XINPUT]):
				if (abs(parent.movement.x) < parent.top):
					parent.movement.x = clamp(parent.movement.x+parent.acc/GlobalFunctions.div_by_delta(delta)*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top)
			else:
				# reverse direction
				parent.movement.x += parent.dec/GlobalFunctions.div_by_delta(delta)*parent.inputs[parent.INPUTS.XINPUT]
				# implament weird turning quirk
				if (sign(parent.movement.x) != sign(parent.movement.x-parent.dec/GlobalFunctions.div_by_delta(delta)*parent.inputs[parent.INPUTS.XINPUT])):
					parent.movement.x = 0.5*60*sign(parent.movement.x)
	else:
		if (parent.movement.x != 0):
			if (sign(parent.movement.x - (parent.frc/GlobalFunctions.div_by_delta(delta))*sign(parent.movement.x)) == sign(parent.movement.x)):
				parent.movement.x -= (parent.frc/GlobalFunctions.div_by_delta(delta))*sign(parent.movement.x)
			else:
				parent.movement.x -= parent.movement.x
	
	# reset state
	if parent.ground:
		var animator: PlayerCharAnimationPlayer = parent.get_avatar().get_animator()
		if animator.current_animation == "roll":
			parent.set_state(parent.STATES.ROLL)
		else:
			parent.set_state(parent.STATES.NORMAL)
			animator.play("RESET")
