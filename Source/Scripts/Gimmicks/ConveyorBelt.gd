tool
extends StaticBody2D

export var speed = 60
var frame = 0
export var length = 1

func _ready():
	$MiddlePiece.region_rect.size.x = length*32
	$LeftCog.position.x = -length*16
	$RightCog.position.x = length*16
	$CollisionShape2D.scale.x = length+1
	constant_linear_velocity.x = speed

func _process(delta):
	if Engine.is_editor_hint():
		$MiddlePiece.region_rect.size.x = length*32
		$LeftCog.position.x = -length*16
		$RightCog.position.x = length*16
		$CollisionShape2D.scale.x = length+1
		
	frame = wrapf(frame+(delta*speed/2),0,3)
	
	$MiddlePiece.frame = (floor(frame)*3)+2
	$LeftCog.frame = (floor(frame)*3)
	$RightCog.frame = (floor(frame)*3)+1
