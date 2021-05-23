extends Node2D
var scattered = false;
var lifetime = 256/Global.originalFPS;
var velocity = Vector2.ZERO;
var player;

func _process(delta):
	# scattered logic
	if (scattered):
		z_index = 7;
		if (lifetime > 0):
			lifetime -= delta;
		else:
			queue_free();
	if (player):
		if (player.ringDisTime <= 0 && (player.invTime*Global.originalFPS <= 90 || scattered)):
			z_index = 1;
			player.get_ring();
			queue_free();

func _physics_process(delta):
	# scattered physics logic
	if (scattered):
		velocity.y += 0.09375*Global.originalFPS;
		translate(velocity*delta);
		if ($FloorCheck.is_colliding() && velocity.y > 0):
			velocity.y *= -0.75;

func _on_Hitbox_body_entered(body):
	if (player != body):
		player = body;


func _on_Hitbox_body_exited(body):
	if (player == body):
		player = null;
