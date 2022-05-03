extends StaticBody2D

export (NodePath) var animator
export var animationName = ""

var active = false

onready var animatorNode = get_node_or_null(animator)


func physics_floor_override(body,caster):
	if (!active):
		$Sprite.region_rect = Rect2(Vector2.ZERO,Vector2(32,8))
		$Sprite.position.y = 4
		active = true
		if (animatorNode != null):
			animatorNode.play(animationName)
	return true
