extends AnimatedSprite2D

var animFinished = false

# fix animation
#func _ready():
	#playing = true

func _on_animation_finished():
	animFinished = true
	visible = false
	if (!$Explode.playing):
		queue_free()

func _on_Explode_finished():
	if (animFinished):
		queue_free()
