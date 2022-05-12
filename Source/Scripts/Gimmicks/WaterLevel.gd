extends Node2D

export var isStatic = false
onready var hoverY = global_position.y

func _ready():
	Global.waterLevel = global_position.y
	$Water.region_rect.size.x = get_viewport_rect().size.x
	
func _process(_delta):
	var cam = GlobalFunctions.getCurrentCamera2D()
	if cam != null:
		$Water.global_position = Vector2(cam.get_camera_screen_center().x,Global.waterLevel)
	$Water.region_rect.position.x = $Water.global_position.x

func _physics_process(_delta):
	if !isStatic:
		global_position.y = hoverY+cos(Global.levelTime*2)*4
		Global.waterLevel = global_position.y


