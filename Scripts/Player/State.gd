## A PlayerCharState is a state that a PlayerChar can be in. A player can only
## be in one active PlayerCharState at a time and the state will invoke its
## process and physics process actions for every frame that state is active for
## the PlayerChar.
class_name PlayerState extends Node

@onready var parent: PlayerChar = get_parent().get_parent()

## Does this state make the player invulnerable (to things like crushing or falling)
@export var invulnerability = false

## This function will be invoked whenever the state is entered
## Override this when creating your state if you need this funcitonality
func state_activated():
	pass

# Override this to take an action on exiting the state
## This function will be invoked whenever the state is exited
## Override this when creating your state if you need this funcitonality
func state_exit():
	pass

# Returns invulnerability status of the state
func get_state_invulnerable():
	return invulnerability

## Process function that the player invokes while this state is active
## Override this when creating your state if you need this funcitonality
func state_process(_delta: float) -> void:
	pass

## Physics function that the player invokes while this state is active
## Override this when creating your state if you need this funcitonality
func state_physics_process(_delta: float) -> void:
	pass
