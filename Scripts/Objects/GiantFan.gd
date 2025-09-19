class_name GiantFan extends Node2D

var _retract_offset: float = 0.0

var activated: bool = false
var _is_deployed: bool = false

signal deployed()
signal retracted()

func _ready() -> void:
	var frames: SpriteFrames = $Sprite.sprite_frames
	for i in frames.get_frame_count("default"):
		_retract_offset = minf(_retract_offset, -frames.get_frame_texture("default", i).get_height())
	$Sprite.offset.y = _retract_offset
	$Sprite.stop()

func _physics_process(delta) -> void:
	var y: float = move_toward($Sprite.offset.y, 0.0 if activated else _retract_offset, delta * 60.0 * 8.0)
	$Sprite.offset.y = y
	if activated:
		if not _is_deployed and y == 0.0:
			_is_deployed = true
			deployed.emit()
	else:
		if _is_deployed and y == _retract_offset:
			_is_deployed = false
			retracted.emit()

func activate() -> void:
	if activated:
		return
	
	$Shutter.play()
	$BigFan.play()
	$Sprite.play("default")
	activated = true

func deactivate():
	if not activated:
		return
	
	$Shutter.play()
	$BigFan.stop()
	$Sprite.stop()
	activated = false
