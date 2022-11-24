extends Sprite

func _on_PlayerAnimation_animation_started(anim_name):
	# handle tails positions based on parents animation
	match (anim_name):
		"roll":
			position = Vector2(0,0)
		_:
			position = Vector2(0,-4)
