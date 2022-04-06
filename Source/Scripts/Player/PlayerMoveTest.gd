extends "res://Scripts/Objects/PhysicsObject.gd"


func _physics_process(delta):
	var input = Vector2(int(Input.is_action_pressed("gm_right"))-int(Input.is_action_pressed("gm_left")),
	int(Input.is_action_pressed("gm_down"))-int(Input.is_action_pressed("gm_up")))
	
	movement += input*delta*100
