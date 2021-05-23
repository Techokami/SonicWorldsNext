extends Sprite

var gravity = 0.21875;
var velocity = Vector2.ZERO;
var lifeTime = Global.originalFPS*5 # 5 seconds

func _physics_process(delta):
	velocity.y += gravity/delta;
	translate(velocity*delta);
