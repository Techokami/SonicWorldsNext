extends KinematicBody2D


export var cast_to = Vector2.ZERO
onready var raycast = $RayCast

func _ready():
	update_cast()

func update_cast():
	raycast.cast_to = cast_to
	raycast.collision_mask = collision_mask


func is_colliding():
	return move_and_collide(cast_to.rotated(global_rotation),true,true,true)

func get_collider():
	if (move_and_collide(cast_to.rotated(global_rotation),true,true,true)):
		return move_and_collide(cast_to.rotated(global_rotation),true,true,true).collider
	return null

func get_collision_normal():
	var col = move_and_collide(cast_to.rotated(global_rotation),true,true,true)
	if (col):
		
		raycast.clear_exceptions()
		raycast.force_raycast_update()
		# check that raycast is colliding with our mover, if it's not then default to the collider
		while (raycast.is_colliding() && raycast.get_collider() != col.collider && !raycast.get_collider() is TileMap):
			raycast.add_exception(raycast.get_collider())
			raycast.force_raycast_update()
		if (raycast.is_colliding()):
			return raycast.get_collision_normal()
		
		return col.normal
	return null

func get_collision_point():
	if (move_and_collide(cast_to.rotated(global_rotation),true,true,true)):
		#return raycast.get_collision_point()
		return move_and_collide(cast_to.rotated(global_rotation),true,true,true).position
	return null

