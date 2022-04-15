extends Node2D



func _on_HitBox_body_entered(body):
	body.movement = (body.global_position-global_position).normalized()*7*Global.originalFPS;
	if body.currentState == body.STATES.JUMP:
		body.set_state(body.STATES.AIR)
	$Bumper.frame = 0;
	$BumperSFX.play();
