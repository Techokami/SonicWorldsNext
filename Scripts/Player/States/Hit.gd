extends PlayerState

func state_physics_process(delta: float) -> void:
	parent.animator.play("hurt")
	# gravity
	parent.movement.y += parent.grv/GlobalFunctions.div_by_delta(delta)
	
	# exit if on floor
	if parent.ground and parent.movement.y >= 0:
		parent.movement.x = 0
		parent.set_state(parent.STATES.NORMAL)
