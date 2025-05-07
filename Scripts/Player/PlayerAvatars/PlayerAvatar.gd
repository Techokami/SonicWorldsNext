## The PlayerAvatar class contains the specific attributes of your character.
## For now this just contains the specific attributes and collision boxes for the character,
## but with future refactoring this could include things like input mappings and per state
## character code.
class_name PlayerAvatar extends Node2D

# All attributes for this base class are used by Sonic
var hitboxes: Array[Vector2] = [
	Vector2(9,19)*2,  # NORMAL
	Vector2(7,14)*2,  # ROLL
	Vector2(9,11)*2,  # CROUCH
	Vector2(16,14)*2, # GLIDE
	Vector2(16,14)*2  # HORIZONTAL
]


## Gets the player animator -- this is a tad overkill most of the time, but
## Sometimes you need to control an animation in a more robust way than simply
## by using play.
func get_animator() -> PlayerCharAnimationPlayer:
	return $PlayerAnimation
	

func get_hitbox(hitbox_type: PlayerChar.HITBOXES):
	return hitboxes[hitbox_type]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

## Override this to add additions to specific states for a given player -- this is useful for
## adding special abilities. You can also provide a total override to the state code if needed
func register_state_modifications(player: PlayerChar):
	pass
	
## Returns the position of the avatar's hands relative to origin (0,0)
## Animations must be set up with a HandsReference position key for this to be particularly
## useful.
## Note: the position will be flipped by X/Y if the sprite is currently flipped.
func get_hands_offset() -> Vector2:
	var hands_reference: Sprite2D = $HandsReference
	var sprite: Sprite2D = $Sprite2D
	var ret_position = hands_reference.position
	if sprite.flip_h:
		ret_position.x *= -1
	if sprite.flip_v:
		ret_position.y *= -1
	return ret_position
