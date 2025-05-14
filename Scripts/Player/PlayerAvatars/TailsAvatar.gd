## The PlayerAvatar class contains the specific attributes of your character.
## For now this just contains the specific attributes and collision boxes for the character,
## but with future refactoring this could include things like input mappings and per state
## character code.
extends PlayerAvatar

# All attributes for this base class are used by Tails
func get_hitbox(hitbox_type: PlayerChar.HITBOXES):
	return hitboxes[hitbox_type]
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	normal_sprite = preload("res://Graphics/Players/Tails.png")
	super_sprite = null
	
	hitboxes = [
		Vector2(9,15)*2,  # NORMAL
		Vector2(7,14)*2,  # ROLL
		Vector2(9,9.5)*2, # CROUCH
		Vector2(10,10)*2, # GLIDE
		Vector2(16,14)*2  # HORIZONTAL
	]

func tails_jump_fly_callback(_state: PlayerState, player: PlayerChar, _delta: float):
	# If Tails is moving upwards faster than the release jump speed, he can't start flying.
	# This prevents an overpowered flight.
	if player.movement.y < -player.releaseJmp * 60:
		return true
	
	if player.any_action_pressed():
		player.set_state(PlayerChar.STATES.FLY)
	
	return true


## Tails is kinda boring, just has flight.
func register_state_modifications(player: PlayerChar):
	var jump_state = player.get_state_object(PlayerChar.STATES.JUMP)
	jump_state.register_process_supplement(tails_jump_fly_callback)
