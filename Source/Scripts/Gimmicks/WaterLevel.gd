extends Node2D

# initial setup for water

# static will make the water stay still, otherwise it drifts in place
export var isStatic = false
onready var hoverY = global_position.y

# art
export var waterSurface = [preload("res://Graphics/Gimmicks/WaterSurface1.png"),preload("res://Graphics/Gimmicks/WaterSurface2.png")]

var frame = 0
export var animSpeed = 8

func _ready():
	# set water level
	Global.setWaterLevel = global_position.y
	Global.waterLevel = global_position.y
	$Water.region_rect.size.x = get_viewport_rect().size.x
	
func _process(delta):
	# set position of the water overlay based on the camera position and size
	var cam = GlobalFunctions.getCurrentCamera2D()
	if cam != null:
		$Water.global_position = Vector2(cam.get_camera_screen_center().x,Global.waterLevel)
	$Water.region_rect.position.x = $Water.global_position.x
	
	# Animation
	frame += delta*animSpeed
	frame = wrapf(frame,0,waterSurface.size())
	
	$Water.texture = waterSurface[floor(frame)]
	

func _physics_process(delta):
	if hoverY != Global.setWaterLevel:
		hoverY = move_toward(hoverY,Global.setWaterLevel,Global.waterScrollSpeed*delta)
		if isStatic:
			global_position.y = hoverY
			Global.waterLevel = global_position.y
	elif isStatic:
		hoverY = global_position.y
	
	if !isStatic:
		global_position.y = hoverY+cos(Global.globalTimer*2)*4
		Global.waterLevel = global_position.y
