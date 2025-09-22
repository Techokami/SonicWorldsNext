class_name BreakableBlockPiece extends Sprite2D

var gravity = 0.21875
var velocity = Vector2.ZERO
var lifeTime = 5 # 5 seconds

## Creates a BreakableBlockPiece object.[br]
## [param parent] - parent object the piece will be attached to.[br]
## [param global_pos] - coordinates to create the Score object at
##                      ([b]not[/b] relative to the [param parent]'s coordinates).[br]
## [param p_velocity] - initial velocity of the newly created piece.[br]
## [param p_texture] - texture of the newly created piece.[br]
## [param p_region_rect] - the region of the texture to display.[br]
## [param z_idx] - Z rendering order of the newly created piece.
static func create(parent: Node, global_pos: Vector2, p_velocity: Vector2,
				   p_texture: Texture2D, p_region_rect: Rect2, z_idx: int) -> BreakableBlockPiece:
	var piece: BreakableBlockPiece = preload("res://Entities/Misc/BlockPiece.tscn").instantiate()
	piece.velocity = p_velocity
	piece.texture = p_texture
	piece.region_rect = p_region_rect
	piece.z_index = z_idx
	parent.add_child(piece)
	piece.global_position = global_pos
	return piece

func _physics_process(delta):
	# increase gravity
	velocity.y += gravity/GlobalFunctions.div_by_delta(delta)
	translate(velocity*delta)
	# life time counter
	lifeTime -= delta
	if lifeTime <= 0:
		queue_free()
