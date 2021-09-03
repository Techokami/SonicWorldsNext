extends KinematicBody2D

export var damageType = 0;
var playerHit = [];

func _process(delta):
	if (playerHit.size() > 0):
		for i in playerHit:
			if (i.get("sprite") != null):
				if (i.sprite.animation == "roll"):
					if (i.velocity.y < 0 || i.global_position.y > global_position.y):
						i.velocity.y -= Global.originalFPS*sign(i.velocity.y);
					else:
						i.velocity.y = -i.velocity.y;
					queue_free();
					return false;
			if (i.has_method("hit_player")):
				i.hit_player(global_position,damageType);

func _on_body_entered(body):
	if (!playerHit.has(body)):
		playerHit.append(body);


func _on_body_exited(body):
	if (playerHit.has(body)):
		playerHit.erase(body);
