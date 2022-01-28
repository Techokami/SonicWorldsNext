@tool
extends AnimatedSprite2D



func _on_Shields_frame_changed():
	match (animation):
		"Default": # regular shield
			z_index = 6;
			offset = Vector2.ZERO;
			scale = Vector2(1,1);
			if (material.blend_mode != 1):#Add
				material.blend_mode = 1#Add
		"Bubble":
			z_index = 6;
			offset = Vector2.ZERO;
			scale.x = 1;
			# flip vertically if frame is odd and greater then 30
			if (fmod(frame,2) == 1 && frame > 30):
				scale.y = -1;
			else:
				scale.y = 1;
			if (material.blend_mode != 0):#disabled
				material.blend_mode = 0
		"Elec":
			if (frame >= 13 && frame < 23):
				z_index = 4;
			else:
				z_index = 6;
			offset = Vector2.ZERO;
			# if frames greater then 5 or 13 and less then 10 and 18, flip horizontaly
			if (frame >= 5 && frame < 10 ||
			frame >= 13 && frame < 18):
				scale.x = -1;
			else:
				scale.x = 1;
			scale.y = 1;
			if (material.blend_mode != 0):#disabled
				material.blend_mode = 0
		"Fire":
			# if frame is odd, make it in front
			if (fmod(frame,2) == 1):
				z_index = 6;
			else:
				z_index = 4;
			# if frames greater then 10, flip vertically
			if (frame >= 10):
				scale.y = -1;
			else:
				scale.y = 1;
			scale.x = 1;
			offset = Vector2.ZERO;
			if (material.blend_mode != 0):#disabled
				material.blend_mode = 0
		_: # default
			z_index = 6;
			offset = Vector2.ZERO;
			scale = Vector2(1,1);
			if (material.blend_mode != 0):#disabled
				material.blend_mode = 0
