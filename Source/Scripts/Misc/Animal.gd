extends Node2D
export (int, "Flap", "Change on fall")var animType = 0;
var animTime = 0;
var bouncePower = 300;
var velocity = Vector2(0,-300);
var speed = 180;

func _ready():
	var rand = round(rand_range(0,1));
	if (rand == 0):
		scale.x = -scale.x;

func _physics_process(delta):
	velocity.y += 0.09375*2*Global.originalFPS;
	translate(velocity*delta);
	if ($FloorCheck.is_colliding() && velocity.y > 0):
		velocity.y = -bouncePower;
		velocity.x = speed*scale.x;

func _process(delta):
	if (velocity.x != 0):
		match (animType):
			0: # flap
				animTime += delta*10;
				if (animTime >= 1):
					animTime = 0;
					$animals.frame = wrapi($animals.frame+1,1,3);
			1: # bounce
				if (velocity.y >= 0):
					$animals.frame = 2;
				else:
					$animals.frame = 1;


func _on_VisibilityNotifier2D_screen_exited():
	queue_free();
