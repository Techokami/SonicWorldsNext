extends KinematicBody2D

func physics_collision(body, hitVector):
	# Not sure if safe.
	if hitVector.y > 0 and body.ground:
		if body.movement.y > 0:
			print(body.movement.y)
		# get_parent().add_weight(1)
		# get_parent().impart_force(body.movement.y)
		# get_parent().set_launch(true)
		get_parent().add_player(body)
		
