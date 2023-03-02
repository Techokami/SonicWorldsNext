extends StaticBody2D

var colCheck = false

func _physics_process(_delta):
	$"../Switch".position.y = -40+(8*int(colCheck))
	# physics_collision are run before colCheck gets updated, so if no one's on the switch this should reset
	colCheck = false

# Collision check
func physics_collision(body, hitVector):
	if hitVector.is_equal_approx((Vector2.DOWN*global_scale.sign()).rotated(deg_to_rad(snapped(global_rotation_degrees,90)))):
		colCheck = true
		get_parent().activate()
