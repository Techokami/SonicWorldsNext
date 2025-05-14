## The PlayerAvatar class contains the specific attributes of your character.
## For now this just contains the specific attributes and collision boxes for the character,
## but with future refactoring this could include things like input mappings and per state
## character code.
extends PlayerAvatar

# All attributes for this base class are used by Shadow
func get_hitbox(hitbox_type: PlayerChar.HITBOXES):
	return hitboxes[hitbox_type]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	normal_sprite = preload("res://Graphics/Players/Shadow.png")
	super_sprite = null
	
	hitboxes = [
		Vector2(9,19)*2,  # NORMAL
		Vector2(7,14)*2,  # ROLL
		Vector2(9,11)*2,  # CROUCH
		Vector2(10,10)*2, # GLIDE
		Vector2(16,14)*2  # HORIZONTAL
	]


## Shadow can break things if he is actively boosting or using power stomp.
func get_break_power(player: PlayerChar) -> int:
	## Coming after Shadow actually has moves
	return super(player)
