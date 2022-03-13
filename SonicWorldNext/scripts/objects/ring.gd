extends Area2D


func _on_ring_body_entered(body):
	Global.play_sound(Global.SOUNDS.RING)
	queue_free()
