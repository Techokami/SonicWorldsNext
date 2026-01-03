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
	parent.movement.y += parent.get_physics().gravity / GlobalFunctions.div_by_delta(delta)
	
	# determine flip based on the direction
	parent.sprite.flip_h = (parent.get_direction_multiplier() < 0.0)
	
	# movement
	var acceleration = parent.get_physics().acceleration
	var deceleration = parent.get_physics().deceleration
	var friction = parent.get_physics().friction
	var top_speed = parent.get_physics().top_speed
	
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		if (parent.movement.x*parent.inputs[parent.INPUTS.XINPUT] < top_speed):
			if (sign(parent.movement.x) == parent.inputs[parent.INPUTS.XINPUT]):
				if (abs(parent.movement.x) < top_speed):
					parent.movement.x = clamp(parent.movement.x+acceleration/GlobalFunctions.div_by_delta(delta)*parent.inputs[parent.INPUTS.XINPUT],-top_speed,top_speed)
			else:
				# reverse direction
				parent.movement.x += deceleration/GlobalFunctions.div_by_delta(delta)*parent.inputs[parent.INPUTS.XINPUT]
				# implament weird turning quirk
				if (sign(parent.movement.x) != sign(parent.movement.x-deceleration/GlobalFunctions.div_by_delta(delta)*parent.inputs[parent.INPUTS.XINPUT])):
					parent.movement.x = 0.5*60*sign(parent.movement.x)
	else:
		if (parent.movement.x != 0):
			if (sign(parent.movement.x - (friction/GlobalFunctions.div_by_delta(delta))*sign(parent.movement.x)) == sign(parent.movement.x)):
				parent.movement.x -= (friction/GlobalFunctions.div_by_delta(delta))*sign(parent.movement.x)
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
