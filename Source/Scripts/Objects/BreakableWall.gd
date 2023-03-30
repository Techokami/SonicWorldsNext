extends StaticBody2D
@export var pieces = Vector2(1,4)
var Piece = preload("res://Entities/Misc/BlockPiece.tscn")
@export var sound = preload("res://Audio/SFX/Gimmicks/Collapse.wav")

@export_enum("Normal","Fragile (CD)")var type = 0
enum TYPE {NORMAL,CD}

func physics_collision(body, hitVector):
	# check hit is either left or right
	if hitVector.x != 0:
		# verify if rolling or knuckles
		if body.animator.current_animation == "roll" and (body.currentState == body.STATES.ROLL and body.ground and abs(body.movement.x) > 4.5*60 or type == TYPE.CD) and !get_collision_layer_value(19) or body.character == body.CHARACTERS.KNUCKLES:
			# disable physics altering masks
			set_collision_layer_value(16,false)
			set_collision_mask_value(14,false)
			# give frame buffer
			await get_tree().process_frame
			$CollisionShape2D.disabled = true
			$Sprite2D.visible = false
			Global.play_sound(sound)
			
			# generate brekable pieces depending on the pieces vector
			for i in range(pieces.x):
				for j in range (pieces.y):
					var piece = Piece.instantiate()
					
					piece.velocity = Vector2(
					lerp(1,2,i/(max(1,pieces.x-1)))*hitVector.x*(4+abs(body.movement.x)/60),
					-pieces.y+j)*60
					
					var spriteWidth = $Sprite2D.texture.get_width()
					var spriteHeight = $Sprite2D.texture.get_height()
					if $Sprite2D.region_enabled:
						spriteWidth = $Sprite2D.region_rect.size.x
						spriteHeight = $Sprite2D.region_rect.size.y
					
					piece.global_position = global_position+Vector2(
					spriteWidth/4*lerp(-1,1,i/(max(1,pieces.x-1))),
					spriteHeight/4*lerp(-1,1,j/(max(1,pieces.y-1)))
					)
					piece.texture = $Sprite2D.texture
					piece.z_index = z_index
					piece.region_rect = Rect2(
					Vector2((spriteWidth/pieces.x)*i,(spriteHeight/pieces.y)*j),
					Vector2(spriteWidth/pieces.x,spriteHeight/pieces.y))
					get_parent().add_child(piece)
		else:
			if sign(body.movement.x) == sign(hitVector.x):
				body.movement.x = 0
				
	return true
