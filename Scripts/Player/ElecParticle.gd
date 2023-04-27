extends Node2D

var speed = 3
var direction = Vector2.RIGHT

func _process(delta):
	translate(direction*speed)
	if (speed > 0):
		speed -= delta*10
	else:
		queue_free()
