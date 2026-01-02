@tool
extends StaticBody2D

@export var speed = 60
var frame = 0
@export var length = 1

func _set_sprite_positions() -> void:
	$MiddlePiece.region_rect.size.x = length * 32.0
	$LeftCog.position.x = -length * 16.0
	$RightCog.position.x = length * 16.0
	$CollisionShape2D.scale.x = 1.0 + length

func _ready():
	# sprite related animations
	_set_sprite_positions()
	# constant linear velocity is a constant speed set in godot's physics
	constant_linear_velocity.x = speed

func _process(delta):
	if Engine.is_editor_hint():
		_set_sprite_positions()
		
	frame = wrapf(frame+(delta*speed/2),0,3)
	
	var anim_frame: int = floori(frame)*3
	$LeftCog.frame = anim_frame
	$RightCog.frame = anim_frame + 1
	$MiddlePiece.frame = anim_frame + 2
