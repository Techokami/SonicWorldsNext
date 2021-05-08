extends KinematicBody2D

var physics = false;
var grv = 0.21875;
var yspeed = 0;
var playerTouch = null;

func destroy():
	$Animator.play("DestroyMonitor");
	$SFX/Destroy.play();
	yield($Animator,"animation_finished");
	$SFX/Ring.play();
	# enable effect
	playerTouch.rings += 10;

func _physics_process(delta):
	if (physics):
		var collide = move_and_collide(Vector2(0,yspeed)*delta);
		yspeed += grv/delta;
		if (collide && yspeed > 0):
			print(collide);
			physics = false;

# Horizontal check
func physics_wall_override(body,caster):
	if (body.velocity.y >= 0 && body.animator.current_animation == "Roll"):
		playerTouch = body;
		destroy();
	else:
		body.velocity.x = 0;

func physics_floor_override(body,caster):
	if (body.animator.current_animation == "Roll"):
		body.velocity.y *= -1;
		body.ground = false;
		playerTouch = body;
		destroy();

func physics_ceiling_override(body,caster):
	if (body.animator.current_animation == "Roll"):
		body.velocity.y *= -1;
		yspeed = -1.5*Global.originalFPS;
		physics = true;
	return true;
