## A PlayerCharState is a state that a PlayerChar can be in. A player can only
## be in one active PlayerCharState at a time and the state will invoke its
## process and physics process actions for every frame that state is active for
## the PlayerChar.
class_name PlayerState extends Node

@onready var parent: PlayerChar

## Does this state make the player invulnerable (to things like crushing or falling)
@export var _invulnerability = false

## Does this state generally leave hands free? Can you grab things in this state?
@export var _hands_free = true

# Stores supplements that get applied when this state is processed
var process_supplements = []


# var physics_process_supplement = [] # Coming if needed


# var entry_supplements = [] # Coming if needed


# Stores supplements that take place when exiting this state
var exit_supplements = []

## Player invokes this to handle the state process. Not meant to be overridden (at least when
## creating actual states and not proxy states)
func state_process_entry(delta: float) -> void:
	# Run the process supplements in order of addition
	for supplement: Callable in process_supplements:
		if !supplement.call(self, parent, delta):
			# First supplement in the chain to returnf false results in the chain stopping early
			# and the main state process function not being ran
			return
			
	state_process(delta)

## Player invokes this to handle state exiting. Not meant to be overridden (at least when creating
## actual states and not proxy states)
## If it returns false, the state transition should be skipped by player.
## If it returns true, state transition should continue as planned.
func state_exit_entry(
	new_state: PlayerChar.STATES,
	new_character_state: int = -1
) -> bool:
	# Run the exit supplements in order of addition
	for supplement: Callable in exit_supplements:
		if supplement.call(self, new_state, parent, new_character_state) == false:
			# If signaled to abort state change, relay that to the caller.
			return false
	
	# Run the state's normal exit routine
	state_exit()

	# This tells the invoker that the state change should continue
	return true


## Registers a process supplement to the state
##
## Process supplements run before the main body of the state process code. You can use them to add
## new character specific functionality to a state.
##
## The supplement function must be a callable of the following format:
## func my_process_supplement_cb(state: PlayerState, player: PlayerChar, delta: float) -> bool
## The arguments will be supplied by the state responsibel for the callback. The state will always
## be the state object invoking the callback, the player will always be the player who owns the
## state, and the delta will be the time difference between this process frame and the last.
## The callback function *MUST* return either true or false. True will tell the process chain to go
## on either to the next supplement or if the supplement is the last supplement in the chain, to the
## normal process function for the state. A false value breaks the chain immediately and returns
## with no further action taking place in either supplements or the state's process function.
##
## See SonicAvatar's shield code and drop dash code for some simple examples. For the most part I
## think you are going to want your supplements to return true unless you have a very specific
## override of the normal state code that you want to do.
func register_process_supplement(supplement: Callable) -> void:
	process_supplements.append(supplement)


## Registers an exit supplement to the state
##
## Exit supplements run during state transitions (set_state() function on player) specifcially when
## the state being exited is also the state that the supplement is bound to. This can be useful for
## intercepting a state transition to apply an effect to the player outside of what is normal for
## the transition. For instance, if transitioning from JUMP to NORMAL, Sonic's drop dash code has
## a supplement set up to check if the drop dash should be applied and if so, instead of simply
## completing the transition to NORMAL, the character will instead switch to ROLL and gain some
## speed.
##
## The supplement function must be a callable of the following format:
## func exit_supplement_cb(
##     state_exiting: PlayerState,
##     state_entering: PlayerChar.STATES,
##     player: PlayerChar
##     character_state_entering: int
## ) -> bool
##
## state_exiting - the state that the supplement is registered to
## state_entering - the state that set_state is trying to transition to (note - uses the state enum
##                  instead of the state object)
## player - the player whose state is in the process of being changed
## character_state_entering - If and only if state_entering is CHARACTERACTION, this is the state
## that CHARACTERACTION will be proxying to if this state change is allowed to continue. I don't
## know yet if anyone is actually going to need this.
##
## The function must return either true or false. Returning true will allow the state change to
## continue after the supplement is ran. Returning false will cancel the state change. You *may*
## perform and additional state change during the execution of this callback, in which case you
## should probably cancel the original state change.
func register_exit_supplement(supplement: Callable):
	exit_supplements.append(supplement)


## This function will be invoked whenever the state is entered
## Override this when creating your state if you need this funcitonality
func state_activated():
	pass


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


## Each state is assigned a hand_free value indicating whether or not the
## player can use their hands to grab things (or whatever else you can
## come up for for why a player might need a free hand to do something).
## You can query this property of the state they are in so that you don't
## need to check every individual state that you may or may not want to
## determine whether or not a gimmick action involving hands should
## take place (such as grabbing a bar or a hook or something).
func get_hands_free() -> bool:
	return _hands_free


## You probably don't want to use this for anything except for really
## free-form states like Animation, but you can use this to change
## whether or not a state should be treated as hands_free. Just make
## sure you change it back when you are ready to turn off that behavior.
func set_hands_free(hands_free: bool) -> void:
	_hands_free = hands_free


## Simple getter for whether or not this state is inherently invulnerable.
func get_invulnerability() -> bool:
	return _invulnerability


## Simply returns the name of the state and the player index of its owner.
## Player index may be -1 if invoked before the player is added to the global players list.
func _to_string() -> String:
	return str(name, ":", Global.get_player_index(parent))


## Sets up the 'parent' value. Make sure to super() if needed in your subclass.
func _ready() -> void:
	var tmp_parent = get_parent()
	var depth = 8 # bail if we go too far
	
	while tmp_parent is not PlayerChar:
		tmp_parent = tmp_parent.get_parent()
		depth -= 1
		if depth == 0:
			break
	
	if tmp_parent is not PlayerChar:
		push_error("Failed to find PlayerChar in state hierarchy")
		return
	
	parent = tmp_parent
	
	
