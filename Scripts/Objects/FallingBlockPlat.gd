extends Sprite2D

var velocity = Vector2.ZERO

func _physics_process(delta):
	translate(velocity*delta)
	velocity.y += delta*600
	if !$VisibleOnScreenNotifier2D.is_on_screen():
		queue_free()
