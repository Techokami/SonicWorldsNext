class_name StateMover extends Node2D

# If this system is used, at least one state zero must be used to kick off the system
var parent

# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent()

# Override this function with the bahavior you want your state to perform when it is entered
func stateProcess(_delta):
	pass
	
# Override this function with the process activities you want your state to perform when it is active
func enterState():
	pass
