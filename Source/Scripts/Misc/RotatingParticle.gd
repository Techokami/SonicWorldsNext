extends AnimatedSprite
var time = 0

func _process(delta):
	position = position.rotated(-deg2rad(360*9*delta))
	time += delta
	if time > 0.3:
		queue_free()
