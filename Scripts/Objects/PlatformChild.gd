extends AnimatableBody2D

# drop condition
func physics_collision(body, hitVector):
	if hitVector.y > 0 and body.ground:
		if get_parent().get("doDrop") != null:
			get_parent().doDrop = true
