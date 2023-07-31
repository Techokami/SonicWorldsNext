extends Sprite2D

var gravity = 0.21875
var velocity = Vector2.ZERO
var lifeTime = 5 # 5 seconds

func _physics_process(delta):
	# increase gravity
	velocity.y += gravity/GlobalFunctions.div_by_delta(delta)
	translate(velocity*delta)
	# life time counter
	if lifeTime > 0:
		lifeTime -= delta
	else:
		queue_free()
