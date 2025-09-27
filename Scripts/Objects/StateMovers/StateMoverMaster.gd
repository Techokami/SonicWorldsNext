# Tool for complex moving objects with multiple states
# Use this node as the parent for another node that you want to move around
# And in addition to the node that you want to move around, create StateMover.gd
# extended classes (StateMoverPositional.gd and StateMoverTranslational.gd included
# as children of the StateMoverMaster. The order of the statemover objects determines
# what their 'state' value is and each statemover can reference other state movers in the tree by
# that number.
#
# example structure:
#
# StateMoverMaster (node2D)
# |_ MyFancyPlatform (possibly just the existing Platform.gd)
# |_ StateMover_01 (node2D with script 'StateMoverPositional' attached
# |_ StateMover_02 (node2D with script 'StateMoverTranslational' attached
# |_ StateMover_03 (node2D with script 'StateMoverPositional' attached

# The first state will have MyFancyPlatform drift over to the location of StateMover_02.
# The second state will then have the platform be moved to a position picked based
# on a vector provided to StateMoverTranslational via exported variable
# The final state will move the platform to the position of StateMover_03

extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var state = -1
var parent

var realPosition
var origin
var states = []

# Called when the node enters the scene tree for the first time.
func _ready():
	realPosition = position
	for i in get_children():
		if i is StateMover:
			states.append(i)
	
	origin = position
	
	if states.size() > 0:
		setState(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func setState(stateIndex):
	var activeState = states[stateIndex]
	activeState.enterState()
	state = stateIndex
	
	
func _process(delta):
	if state == -1:
		return

	var activeState = states[state]
	activeState.stateProcess(delta)
	
func _physics_process(delta):
	if state == -1:
		return
		
	var activeState = states[state]
	activeState.statePhysicsProcess(delta)
	position = realPosition.floor()
	
	
