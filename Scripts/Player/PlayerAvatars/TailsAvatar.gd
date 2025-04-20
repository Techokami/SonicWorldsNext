## The PlayerAvatar class contains the specific attributes of your character.
## For now this just contains the specific attributes and collision boxes for the character,
## but with future refactoring this could include things like input mappings and per state
## character code.
extends PlayerAvatar

# All attributes for this base class are used by Sonic

# All attributes for this base class are used by Sonic
func get_hitbox(hitbox_type: PlayerChar.HITBOXES):
	return hitboxes[hitbox_type]
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hitboxes = [
		Vector2(9,15)*2,  # NORMAL
		Vector2(7,14)*2,  # ROLL
		Vector2(9,9.5)*2, # CROUCH
		Vector2(10,10)*2, # GLIDE
		Vector2(16,14)*2  # HORIZONTAL
	]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
