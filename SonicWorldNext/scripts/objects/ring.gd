extends Area2D


func _on_ring_body_entered(body):
	queue_free()
