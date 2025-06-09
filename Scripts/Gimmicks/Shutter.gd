@tool
extends CharacterBody2D

const OPEN_AREA_DEFAULT_WIDTH: float = 120.0

@export var texture: Texture2D = preload("res://Graphics/Obstacles/Walls/shutter.png"):
	set(value):
		texture = value
		if is_node_ready():
			$Shutter.texture = texture
			_update_areas()

enum SIDE { LEFT, RIGHT, SWITCH }
@export var side: SIDE = SIDE.LEFT:
	set(value):
		side = value
		if is_node_ready():
			_update_areas()

@export var open: bool = false:
	set(value):
		open = value
		currently_open = value
var currently_open: bool = open:
	set(value):
		var prev_value: bool = currently_open
		currently_open = value
		if is_node_ready():
			if Engine.is_editor_hint():
				# open/close the door
				$Shutter.position.y = -texture.get_height() if value else 0
			elif value != prev_value:
				$ShutterSound.play()
			_update_areas()

func _update_areas() -> void:
	if Engine.is_editor_hint():
		# hide masks if side is set to switch
		# (also, hide CloseArea if the door is initially open)
		var not_switch: bool = (side != SIDE.SWITCH)
		$OpenArea/Mask.visible = not_switch
		$CloseArea/Mask.visible = not_switch and not open
		$CloseArea2/Mask.visible = not_switch
		$Mask.visible = not currently_open
	else:
		# disable the mask if the door is open
		$Mask.disabled = currently_open
		# disable detection areas if side is switch
		# (also, disable CloseArea if the door is initially open)
		var switch: bool = (side == SIDE.SWITCH)
		$OpenArea/Mask.disabled = switch
		$CloseArea/Mask.disabled = switch or open
		$CloseArea2/Mask.disabled = switch
	if side != SIDE.SWITCH:
		# sanity checks
		assert($Mask.shape is RectangleShape2D)
		assert($OpenArea/Mask.shape is RectangleShape2D)
		# set areas
		var door_shape: RectangleShape2D = $Mask.shape as RectangleShape2D
		door_shape.size = texture.get_size()
		$CloseArea/Mask.shape = door_shape
		$CloseArea2/Mask.shape = door_shape
		var side_sign: float = -1 if side == SIDE.LEFT else 1
		var door_width: float = door_shape.size.x
		var open_area_width: float = OPEN_AREA_DEFAULT_WIDTH - door_width / 2.0
		$OpenArea/Mask.shape.size = Vector2(open_area_width, door_shape.size.y)
		var open_area_pos_x = (OPEN_AREA_DEFAULT_WIDTH + door_width / 2.0) / 2.0
		$OpenArea.position.x = open_area_pos_x * side_sign
		var close_area_offset: float = (open_area_width + door_width) / 2.0
		$CloseArea.position.x = (open_area_pos_x + close_area_offset) * side_sign
		$CloseArea2.position.x = (open_area_pos_x - close_area_offset - door_width) * side_sign

func _ready() -> void:
	$Shutter.texture = texture
	$Shutter.position.y = -texture.get_height() if currently_open else 0
	_update_areas()

func _process(delta) -> void:
	if not Engine.is_editor_hint():
		# move shutter
		$Shutter.position = $Shutter.position.move_toward(Vector2(0.0, -texture.get_height() if currently_open else 0), delta * 512.0)
		# disable mask if opened
		$Mask.disabled = currently_open

func _physics_process(_delta: float) -> void:
	if $OpenArea.has_overlapping_bodies():
		currently_open = true
	elif $CloseArea.has_overlapping_bodies() or $CloseArea2.has_overlapping_bodies():
		currently_open = false

# force open and force close is used for switches
func force_open() -> void:
	currently_open = true

func force_close() -> void:
	currently_open = false
