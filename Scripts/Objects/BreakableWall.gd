extends StaticBody2D

## How many pieces make up the wall (affects splitting).
@export var pieces = Vector2(1,4)

## Each broken piece will use this scene.
var Piece = preload("res://Entities/Misc/BlockPiece.tscn")

## Sound to play when breaking the wall.
@export var sound = preload("res://Audio/SFX/Gimmicks/Collapse.wav")

enum TYPE {
	NORMAL, ## The wall requires most characters to be moving at a fairly high speed to break.
	CD ## The wall is made of paper and any roll will break it.
}
@export var type: TYPE = TYPE.NORMAL


## Breaks the wall, plays the break sound and creates broken pieces.
func break_wall(player: PlayerChar, hitVector):
	# disable physics altering masks
	set_collision_layer_value(16,false)
	set_collision_mask_value(14,false)
	$CollisionArea.set_collision_mask_value(20,false)
	# give frame buffer
	await get_tree().process_frame
	$CollisionShape2D.disabled = true
	$CollisionArea/CollisionShape2D.disabled = true
	$Sprite2D.visible = false
	Global.play_sound(sound)
	
	# generate brekable pieces depending on the pieces vector
	for i in range(pieces.x):
		for j in range (pieces.y):
			var piece = Piece.instantiate()
	
			piece.velocity = Vector2(
			lerp(1,2,i/(max(1,pieces.x-1)))*hitVector.x*(4+abs(player.movement.x)/60),
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

## Checks if the player can break the wall.
func physics_collision(body: PlayerChar, hitVector):
	# check hit is either left or right
	if hitVector.x != 0:
		# If the player is Knuckles or Amy doing the hammer attack, or Sonic
		# (or potentially any other character who's able to use shields)
		# using Fire Shield ability, it's an auto-break.
		if body.character == Global.CHARACTERS.KNUCKLES or \
		   body.character == Global.CHARACTERS.AMY and body.get_state() == PlayerChar.STATES.AMYHAMMER or \
		   (body.get_shield() == PlayerChar.SHIELDS.FIRE and body.get_state() == PlayerChar.STATES.JUMP and
		   body.shieldSprite.animation == "FireAction"):
			break_wall(body, hitVector)
			return
		
		# Non-Knuckles characters can't break
		if get_collision_layer_value(19):
			# If they are moving against it, they also get stopped
			if sign(body.movement.x) == sign(hitVector.x):
				body.movement.x = 0
			return
		
		if body.get_state() == PlayerChar.STATES.ROLL and \
			(abs(body.movement.x) > 4.5 * 60 or type == TYPE.CD):
			break_wall(body, hitVector)
			# TODO Add conditional player kickback
			return 

		# If they failed to break it while moving against it, they get stopped
		if sign(body.movement.x) == sign(hitVector.x):
			body.movement.x = 0
				
	return

func _on_CollisionArea_area_entered(area: Area2D) -> void:
	if area.name == "InstaShieldHitbox":
		var player: PlayerChar = area.get_parent().get_parent()
		if player.character == Global.CHARACTERS.AMY:
			# It should be okay to have either (1,0) or (-1,0) as a hit vector,
			# as the Y part of the vector is not used by break_wall() anyway
			var hit_vector: Vector2 = Vector2(sign(global_position.x - player.global_position.x), 0.0)
			break_wall(player, hit_vector)
