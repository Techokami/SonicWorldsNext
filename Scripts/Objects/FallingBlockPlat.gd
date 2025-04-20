class_name FallingBlock extends Sprite2D

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 600.0
var release_delay: float = 0.0
var cur_time: float = 0.0

func _physics_process(delta):
	cur_time += delta
	
	if cur_time < release_delay: 
		return
	
	translate(velocity*delta)
	velocity.y += delta*gravity
	if !$VisibleOnScreenNotifier2D.is_on_screen():
		queue_free()
