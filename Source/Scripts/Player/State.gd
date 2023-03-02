class_name PlayerState extends Node

@onready var parent = get_parent().get_parent()

# Does this state make the player complete invulnerable (to things like crushing or falling)
var invulnerability = false

# Override this to take an action on entering the state
func state_activated():
	pass

# Override this to take an action on exiting the state
func state_exit():
	pass

# Returns invulnerability status of the state
func get_state_invulnerable():
	return invulnerability
