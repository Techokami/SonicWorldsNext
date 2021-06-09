extends RayCast2D

func _physics_process(delta):
	if Input.is_action_pressed("ui_end"):
		if (is_colliding()):
			var collider = get_collider();
			if (collider.has_method("collision_check")):
				#var getPose = get_collision_point();
				#print("Pose: ",getPose);
				#while (collider.collision_check(getPose)):
				#	getPose.y -= 1;#collider.get_height(getPose);
				#print(collider.get_meta_tile(getPose));
				var getPose = collider.get_surface_point(global_position,cast_to.y);
				if (getPose != null):
					$Polygon2D2.global_position = getPose;
					$Polygon2D2.rotation = collider.get_angle(getPose);
					print(getPose);
				#print(collider.get_angle(getPose));
				#print("Surface: ",collider.get_surface_point(global_position,cast_to.y));
				#print(getPose.y);
		position.x += 1;
	if Input.is_action_pressed("ui_home"):
		position.x -= 1;
