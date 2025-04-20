extends AnimatableBody2D

func physics_collision(body: PlayerChar, hit_vector):
	if hit_vector.y > 0 and body.ground:
		get_parent().get_parent().attach_player(body)
