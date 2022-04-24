extends StaticBody2D

var bumperCount = 0


func physics_collision(body, hitVector):
	body.movement = (body.global_position-global_position).normalized()*7*Global.originalFPS;
	if body.currentState == body.STATES.JUMP:
		body.set_state(body.STATES.AIR)
	$Bumper.frame = 0;
	Global.play_sound($BumperSFX.stream)
	if bumperCount < 10:
		Global.score(global_position,0)
		bumperCount += 1
