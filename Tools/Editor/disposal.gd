extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Automatically deletes the node and everything in it on load.
	self.queue_free()
