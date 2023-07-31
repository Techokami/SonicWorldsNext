extends Sprite2D

var velocity = Vector2.ZERO
var gravity = 600

func _physics_process(delta):
	translate(velocity*delta)
	velocity.y += delta*gravity
	if !$VisibleOnScreenNotifier2D.is_on_screen():
		queue_free()
