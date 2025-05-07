## A PlayerCharState is a state that a PlayerChar can be in. A player can only
## be in one active PlayerCharState at a time and the state will invoke its
## process and physics process actions for every frame that state is active for
## the PlayerChar.
class_name PlayerState extends Node

@onready var parent: PlayerChar = get_parent().get_parent()

## Does this state make the player invulnerable (to things like crushing or falling)
@export var invulnerability = false

# process supplements should take the form of a function that takes a state object, a playerchar,
# and a delta.
#
# It should and return either true to indicate that the execution of the normal state code
# (and/or next supplement) should go on or else a false to indicate that execution of the state
# should stop with that supplement.
#
# Supplements are the main intended way of adding per character functionality to a state. This is
# largely where your characters' special moves belong when they don't just need their own states.
var process_supplements = []
var physics_process_supplement = []
var entry_supplements = []
var exit_supplements = []

## Player invokes this to handle the state process. Not meant to be overridden
func state_process_entry(delta: float) -> void:
	
	for supplement: Callable in process_supplements:
		if !supplement.call(self, parent, delta):
			return
			
	state_process(delta)


## This function will be invoked whenever the state is entered
## Override this when creating your state if you need this funcitonality
func state_activated():
	pass


# Returns invulnerability status of the state
func get_state_invulnerable():
	return invulnerability


## This function will be invoked whenever the state is exited
## Override this when creating your state if you need this funcitonality
func state_exit():
	pass


## Process function that the player invokes while this state is active
## Override this when creating your state if you need this funcitonality
func state_process(_delta: float) -> void:
	pass


## Physics function that the player invokes while this state is active
## Override this when creating your state if you need this funcitonality
func state_physics_process(_delta: float) -> void:
	pass
