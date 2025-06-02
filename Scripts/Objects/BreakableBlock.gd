extends StaticBody2D
@export var pieces = Vector2(2,2)
@export var sound = preload("res://Audio/SFX/Gimmicks/Collapse.wav")
@export var score = true

func physics_collision(body, hitVector):
	# check if physics object is coming down and check for a bit where the player isn't on floor
	if hitVector == Vector2.DOWN and body.get_collision_layer_value(20):
		var parent: Node = get_parent()
		
		# disable collision
		$CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		Global.play_sound(sound)
		
		# set player variables
		body.ground = false
		body.movement.y = -3*60
		if score:
			Score.create(parent, global_position, Global.SCORE_COMBO[min(Global.SCORE_COMBO.size()-1,body.enemyCounter)])
		body.enemyCounter += 1
		
		var sprite_texture: Texture2D = $Sprite2D.texture
		var sprite_width: int = sprite_texture.get_width()
		var sprite_height: int = sprite_texture.get_height()
		if $Sprite2D.region_enabled:
			sprite_width = $Sprite2D.region_rect.size.x
			sprite_height = $Sprite2D.region_rect.size.y
		
		# generate pieces of the block to scatter, use i and j to determine the velocity of each one
		# and set the settings for each piece to match up with the $Sprite2D node
		for i: float in range(pieces.x):
			for j: float in range(pieces.y):
				BreakableBlockPiece.create(
					parent,
					global_position+Vector2(
						sprite_width/4*lerp(-1,1,i/(pieces.x-1)),
						sprite_height/4*lerp(-1,1,j/(pieces.y-1))),
					Vector2((pieces.y-j)*lerp(-1,1,i/(pieces.x-1)),-pieces.y+j)*60,
					sprite_texture,
					Rect2(
						Vector2((sprite_width/pieces.x)*i,(sprite_height/pieces.y)*j),
						Vector2(sprite_width/pieces.x,sprite_height/pieces.y)),
					z_index)
				
	return true
