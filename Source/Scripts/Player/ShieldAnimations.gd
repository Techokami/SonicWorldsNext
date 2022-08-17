tool
extends AnimatedSprite


func _process(_delta):
	# prevent rotation
	if (!Engine.is_editor_hint()):
		global_rotation = 0


func _on_Shields_frame_changed():
	match (animation):
		"Default": # regular shield
			z_index = 6
			offset = Vector2.ZERO
			scale = Vector2(1,1)
			if (material.blend_mode != BLEND_MODE_ADD):
				material.blend_mode = BLEND_MODE_ADD
		"Bubble":
			z_index = 6
			offset = Vector2.ZERO
			scale.x = 1
			# flip vertically if frame is odd and greater then 30
			if (fmod(frame,2) == 1 and frame > 30):
				scale.y = -1
			else:
				scale.y = 1
			if (material.blend_mode != BLEND_MODE_DISABLED):
				material.blend_mode = BLEND_MODE_DISABLED
		"Elec":
			if (frame >= 13 and frame < 23):
				z_index = 4
			else:
				z_index = 6
			offset = Vector2.ZERO
			# if frames greater then 5 or 13 and less then 10 and 18, flip horizontaly
			if (frame >= 5 and frame < 10 or
			frame >= 13 and frame < 18):
				scale.x = -1
			else:
				scale.x = 1
			scale.y = 1
			if (material.blend_mode != BLEND_MODE_DISABLED):
				material.blend_mode = BLEND_MODE_DISABLED
		"Fire":
			# if frame is odd, make it in front
			if (fmod(frame,2) == 1):
				z_index = 6
			else:
				z_index = 4
			# if frames greater then 10, flip vertically
			if (frame >= 10):
				scale.y = -1
			else:
				scale.y = 1
			scale.x = 1
			offset = Vector2.ZERO
			if (material.blend_mode != BLEND_MODE_DISABLED):
				material.blend_mode = BLEND_MODE_DISABLED
		_: # default
			z_index = 6
			offset = Vector2.ZERO
			scale = Vector2(1,1)
			if (material.blend_mode != BLEND_MODE_DISABLED):
				material.blend_mode = BLEND_MODE_DISABLED
