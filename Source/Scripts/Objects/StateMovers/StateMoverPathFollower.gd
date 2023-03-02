extends "res://Scripts/Objects/StateMovers/StateMover.gd"

@export var moveTime = 4.0 # takes 4 seconds to reach target position
@export var nextState = 1

var curTime = 0.0

var offsetPosition
var path
var curve # The first child of this node MUST BE your custom Path2D
var bakedLength

enum INTERPOLATION {COS, LINEAR}
@export var interpolationMode: INTERPOLATION = INTERPOLATION.COS

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	path = get_children()[0]
	curve = path.get_curve()
	
	if position != Vector2(0, 0):
		printerr("StateMoverPathFollower object should be at position (0,0) within the StateMoverMaster. Expect misaligned pathing.")
		
	pass
	
func enterState():
	curTime = 0.0
	offsetPosition = parent.origin
	parent.realPosition = curve.get_point_position(0) + offsetPosition
	bakedLength = curve.get_baked_length()
	
	pass

func stateProcess(delta):
	curTime += delta
	
func statePhysicsProcess(_delta):
	
	if interpolationMode == INTERPOLATION.COS:
		var interpolationPeriod = 0.5 * -cos((curTime / moveTime) * PI) + 0.5
		var interpolationPosition = interpolationPeriod * bakedLength
		parent.realPosition = curve.interpolate_baked(interpolationPosition) + offsetPosition
		pass
	else:
		var interpolationPosition = (curTime / moveTime) * bakedLength
		parent.realPosition = curve.interpolate_baked(interpolationPosition) + offsetPosition
		pass
	
	if curTime >= moveTime:
		parent.setState(nextState)
	
	pass
