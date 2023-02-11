extends KinematicBody2D

func physics_collision(body, hitVector):
	# Not sure if safe.
	if hitVector.y > 0 and body.ground:
		get_parent().add_player(body)
