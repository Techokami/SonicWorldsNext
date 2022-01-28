extends AnimatedSprite2D

func _ready():
	playing = true;

func _on_animation_finished():
	queue_free();
