extends KinematicBody2D


export var cast_to = Vector2.ZERO


func is_colliding():
	return move_and_collide(cast_to.rotated(global_rotation),true,true,true)

func get_collider():
	if (move_and_collide(cast_to.rotated(global_rotation),true,true,true)):
		return move_and_collide(cast_to.rotated(global_rotation),true,true,true).collider
	return null

func get_collision_normal():
	if (move_and_collide(cast_to.rotated(global_rotation),true,true,true)):
		return move_and_collide(cast_to.rotated(global_rotation),true,true,true).normal
	return null

func get_collision_point():
	if (move_and_collide(cast_to.rotated(global_rotation),true,true,true)):
		return move_and_collide(cast_to.rotated(global_rotation),true,true,true).position
	return null
