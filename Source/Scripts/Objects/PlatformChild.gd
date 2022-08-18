extends KinematicBody2D


func physics_collision(body, hitVector):
	if hitVector.y > 0 and body.ground:
		get_parent().doDrop = true
