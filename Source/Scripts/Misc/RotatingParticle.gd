extends AnimatedSprite
var time = 0
var direction = 1
var velocity = Vector2.ZERO


func _process(delta):
	# rotate
	position = position.rotated(deg2rad(360*5*delta)*direction)
	translate(velocity*0.5*delta)
	time += delta
	if time > 0.3:
		queue_free()
