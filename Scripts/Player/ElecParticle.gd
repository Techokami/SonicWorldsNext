extends Node2D

const SPEED: float = 2.0 * 60.0

var direction: Vector2 = Vector2.RIGHT
var time: float = 1.0 / 60.0 * 22.0

func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	time -= delta
	if time <= 0.0:
		queue_free()
