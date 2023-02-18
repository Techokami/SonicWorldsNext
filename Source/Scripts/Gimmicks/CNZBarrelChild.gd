extends KinematicBody2D

# drop condition
func physics_collision(body, hitVector):
	if hitVector.y > 0 and body.ground:
		get_parent().attach_player(body)
