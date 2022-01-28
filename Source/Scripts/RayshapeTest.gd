extends CharacterBody2D


func _physics_process(delta):
	if (Input.is_action_pressed("ui_end")):
		move_and_collide(Vector2.DOWN*delta*60)
	if (Input.is_action_pressed("ui_home")):
		move_and_collide(Vector2.UP*delta*60)
	
	#$PsudoRaycast.position = Vector2(11,0)
	var col = $PsudoRaycast.move_and_collide(Vector2.DOWN*8,true)
	if (col):
		position.y = col.position.y-8
