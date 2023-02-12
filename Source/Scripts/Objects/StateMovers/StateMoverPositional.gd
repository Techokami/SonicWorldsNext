extends "res://Scripts/Objects/StateMovers/StateMover.gd"

export var moveTime = 4.0 # takes 4 seconds to reach target position

var startPos
var endPos
export var nextState = 1

enum INTERPOLATION {COS, LINEAR}
export(INTERPOLATION) var interpolationMode = INTERPOLATION.COS

var curTime = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	._ready()
	endPos = Vector2(global_position)
	pass
	
func enterState():
	startPos = Vector2(parent.global_position)
	curTime = 0.0
	pass

func stateProcess(delta):
	curTime += delta
	
func statePhysicsProcess(_delta):
	if interpolationMode == INTERPOLATION.COS:
		parent.realPosition = 0.5 * (endPos + startPos) + 0.5 * (endPos - startPos) * (-cos(curTime * PI / moveTime))
	else:
		parent.realPosition = startPos + (endPos - startPos) * (curTime / moveTime)

	if curTime >= moveTime:
		parent.realPosition = endPos
		parent.setState(nextState)
		
	pass
