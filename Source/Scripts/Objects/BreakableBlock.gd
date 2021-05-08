extends StaticBody2D


func physics_floor_override(body,caster):
	if (body.animator.current_animation == "Roll"):
		$CollisionShape2D.disabled = true;
		$Sprite.visible = false;
		body.ground = false;
		body.velocity.y = -3*Global.originalFPS;
	return true;
