## The character action state is a proxy state that is used to reference the fact that the
## character is actually working in another state that is invisible to the normal PlayerChar
## states enumerator. This helps us keep character-specific states out of the base player code
## and sequestered to the characters themselves.

class_name CharacterActionState extends PlayerState

# Stores the actual state that we are proxying to
var _character_action_state: PlayerState
var _character_action_index: int

## Sets the state that this state is currently proxying to
func set_character_action_state(character_action_state: int) -> void:
	_character_action_state = parent.get_avatar().character_state_list[character_action_state]
	_character_action_index = character_action_state


## Gets the character-action state that this state is currently proxying to.
func get_character_action_state_obj() -> PlayerState:
	return _character_action_state


func get_character_action_state_index() -> int:
	return _character_action_index


## Proxies to the character-specific state's state_process_entry function
func state_process_entry(delta: float) -> void:
	# Run the process supplements in order of addition
	return _character_action_state.state_process_entry(delta)


## Physics function that the player invokes while this state is active
## Override this when creating your state if you need this funcitonality
func state_physics_process(delta: float) -> void:
	return _character_action_state.state_physics_process(delta)


## Proxies to the character-specific state's state_exit_entry function
func state_exit_entry(new_state: PlayerChar.STATES, new_character_state: int = -1) -> bool:
	var ret: bool = _character_action_state.state_exit_entry(new_state, new_character_state)
	
	if ret:
		_character_action_state = null
	
	return ret


func register_process_supplement(_supplement: Callable) -> void:
	push_error("Attempted to register_process_supplement to CharacterAction state. This is ",
	           "a proxy state and not intended for use in this way.")
	return


func register_exit_supplement(_supplement: Callable):
	push_error("Attempted to register_exit_supplement to CharacterAction state. This is ",
	           "a proxy state and not intended for use in this way.")
	return


func set_hands_free(_new_hands_free: bool) -> void:
	push_error("Attempted to set_hands-free to CharacterAction state. This is a proxy state",
	           "and not intended for use in this way.")


## Proxies to the character-specific state's get_invulnerability function
func get_invulnerability() -> bool:
	return _invulnerability


## Proxies to the character-specific state's get_hands_free function
func get_hands_free() -> bool:
	return _character_action_state.get_hands_free()


## Includes the name of the state we are proxying to as well as our own.
func _to_string() -> String:
	return str(name, ":", Global.get_player_index(parent))
