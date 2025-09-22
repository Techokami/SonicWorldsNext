extends StaticBody2D

## How many pieces make up the wall (affects splitting).
@export var pieces = Vector2(1,4)

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
	# give frame buffer
	await get_tree().process_frame
	$CollisionShape2D.disabled = true
	$Sprite2D.visible = false
	Global.play_sound(sound)
	
	# generate brekable pieces depending on the pieces vector
	var sprite_size: Vector2 = \
		$Sprite2D.region_rect.size if $Sprite2D.region_enabled else $Sprite2D.texture.size()
	var piece_size: Vector2 = sprite_size/pieces
	for i in range(pieces.x):
		for j in range (pieces.y):
			BreakableBlockPiece.create(
				get_parent(),
				global_position+sprite_size/4.0*Vector2(
					lerp(-1,1,i/(max(1,pieces.x-1))),
					lerp(-1,1,j/(max(1,pieces.y-1)))),
				Vector2(lerp(1,2,i/(max(1,pieces.x-1)))*hitVector.x*(4+abs(player.movement.x)/60.0),
					-pieces.y+j)*60.0,
				$Sprite2D.texture,
				Rect2(piece_size*Vector2(i,j),piece_size),
				z_index)

## Checks if the player can break the wall.
func physics_collision(body: PlayerChar, hitVector):
	# check hit is either left or right
	if hitVector.x != 0:
		
		#XXX TODO Need to fix this script to use character break force for all checks
		
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
