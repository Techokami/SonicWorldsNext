extends "res://Scripts/Player/State.gd"


func _physics_process(delta):
	parent.animator.play("hurt")
	# gravity
	parent.movement.y += 0.1875/GlobalFunctions.div_by_delta(delta)
	
	# exit if on floor
	if (parent.ground):
		parent.movement.x = 0
		parent.set_state(parent.STATES.NORMAL)
