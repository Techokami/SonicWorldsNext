extends Area2D

var players = []
export (int, "left", "right") var forceDirection = 1

func _physics_process(delta):
	if players.size() > 0:
		for i in players:
			if i.ground:
				if (i.movement*Vector2(1,0)).is_equal_approx(Vector2.ZERO):
					i.movement.x = 2*sign(-1+(forceDirection*2))*Global.originalFPS
				if i.currentState != i.STATES.ROLL:
					i.set_state(i.STATES.ROLL)
					#i.sprite.play("roll");
					i.sfx[1].play();

func _on_ForceRoll_body_entered(body):
	if !players.has(body):
		players.append(body)


func _on_ForceRoll_body_exited(body):
	if players.has(body):
		players.erase(body)
