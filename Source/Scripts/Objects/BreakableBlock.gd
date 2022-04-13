extends StaticBody2D
export var pieces = Vector2(2,2)
var Piece = preload("res://Entities/Misc/BlockPiece.tscn")

func physics_collision(body, hitVector):
	#print(hitVector,": ",-hitDirection)
	if hitVector == Vector2.DOWN && body.animator.current_animation == "roll":
		$CollisionShape2D.disabled = true
		$Sprite.visible = false
		body.ground = false
		body.movement.y = -3*Global.originalFPS
		for i in range(pieces.x):
			for j in range (pieces.y):
				var piece = Piece.instance()
				
				piece.velocity = Vector2(
				(pieces.y-j)*lerp(-1,1,i/(pieces.x-1)),
				-pieces.y+j)*Global.originalFPS
				
				var spriteWidth = $Sprite.texture.get_width()
				var spriteHeight = $Sprite.texture.get_height()
				
				piece.global_position = global_position+Vector2(
				spriteWidth/4*lerp(-1,1,i/(pieces.x-1)),
				spriteHeight/4*lerp(-1,1,j/(pieces.y-1))
				)
				
				piece.region_rect = Rect2(
				Vector2((spriteWidth/pieces.x)*i,(spriteHeight/pieces.y)*j),
				Vector2(spriteWidth/pieces.x,spriteHeight/pieces.y))
				get_parent().add_child(piece)
				
	return true
