extends Sprite2D

var defaultPosition = position

func _on_PlayerAnimation_animation_started(anim_name):
	# handle tails positions based on parents animation
	match (anim_name):
		"roll":
			position = defaultPosition+Vector2(0,4)
		_:
			position = defaultPosition
