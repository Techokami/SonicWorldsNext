## The PlayerAvatar class contains the specific attributes of your character.
## For now this just contains the specific attributes and collision boxes for the character,
## but with future refactoring this could include things like input mappings and per state
## character code.
class_name KnucklesAvatar extends PlayerAvatar

## Order of CHAR_STATES should be the same as the order of nodes under CharacterStates in
## AmyAvatar's scene file.
enum CHAR_STATES {
	KNUCKLES_CLIMB,
}

func get_hitbox(hitbox_type: PlayerChar.HITBOXES):
	return hitboxes[hitbox_type]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	normal_sprite = preload("res://Graphics/Players/Knuckles.png")
	super_sprite = null
	
	hitboxes = [
		Vector2(9,19)*2,  # NORMAL
		Vector2(7,14)*2,  # ROLL
		Vector2(9,11)*2,  # CROUCH
		Vector2(10,10)*2, # GLIDE
		Vector2(16,14)*2  # HORIZONTAL
	]

func knuckles_jump_glide_callback(_state: PlayerState, player: PlayerChar, _delta: float):

	if player.movement.y < -player.get_physics().release_jump * 60:
		return true
	
	if player.any_action_pressed():
		player.movement = Vector2(player.get_direction_multiplier()*4*60, max(player.movement.y, 0))
		player.set_state(PlayerChar.STATES.GLIDE, hitboxes[3])
	
	return true


## Tails is kinda boring, just has flight.
func register_state_modifications(player: PlayerChar):
	var jump_state = player.get_state_object(PlayerChar.STATES.JUMP)
	jump_state.register_process_supplement(knuckles_jump_glide_callback)


## Knuckles always breaks everything effortlessly through his mere presence.
func get_break_power(_player: PlayerChar) -> int:
	return 5
