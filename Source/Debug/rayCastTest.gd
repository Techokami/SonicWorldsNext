extends RayCast2D

func _process(delta):
	if (is_colliding()):
		translate(get_collision_point()-position)
