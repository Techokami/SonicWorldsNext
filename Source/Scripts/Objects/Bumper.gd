extends Node2D



func _on_HitBox_body_entered(body):
	body.velocity = (body.global_position-global_position).normalized()*7*Global.originalFPS;
	$Bumper.frame = 0;
	$BumperSFX.play();
