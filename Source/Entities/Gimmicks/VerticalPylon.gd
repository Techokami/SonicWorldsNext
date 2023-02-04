tool
extends Node2D

# Vertical size of the pylon (center only - edges are constant sized)
export var vert_size = 96
# Can't go above this many pixels from the top
export var upper_margin = 16
# Can't go below this many pixels from the bottom
export var lower_margin = 16

var last_size

# XXX test crap
var offsetTimer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		# Update the sprites used... this can happen later.
		last_size = vert_size
		return
		
	pass # Replace with function body.
	
func _process(delta):
	if Engine.is_editor_hint():
		var mainSprite = $FBZ_Pylon_Sprite
		var topSprite = $FBZ_Pylon_Top
		var bottomSprite = $FBZ_Pylon_Bottom
		
		if (last_size == vert_size):
			return

		last_size = vert_size
		mainSprite.set_region_rect(Rect2(0, 0, 48, vert_size))
		mainSprite.position = Vector2(0, -vert_size / 2 - bottomSprite.texture.get_height() / 2)
		topSprite.position = mainSprite.position + Vector2(0, (-vert_size / 2) - (topSprite.texture.get_height() / 4))
		bottomSprite.position = mainSprite.position + Vector2(0, (vert_size / 2) + (bottomSprite.texture.get_height() / 4) + 1)
		
		
		return
		
func _draw():
	if Engine.is_editor_hint():
		pass
