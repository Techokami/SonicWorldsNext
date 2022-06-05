extends Node2D

# 0 = normal, 1 = medium, 2 = airbubble
var bubbleType = 0

var velocity = Vector2(1,-32)
onready var offsetTime = randf()*4

func _ready():
	$Bubble.frame = 0
	match(bubbleType):
		0:
			$Bubble.play("default")
		1:
			$Bubble.play("medium")
		2:
			$Bubble.play("air")
			$BubbleCollect/CollisionShape2D.disabled = false

func _on_Bubble_animation_finished():
	if $Bubble.animation == "bigPop":
		queue_free()

func _physics_process(delta):
	if Global.waterLevel != null:
		if global_position.y > Global.waterLevel:
			translate(velocity*delta)
			offsetTime += delta
			velocity.x = cos(offsetTime*4)*8
		else:
			if $Bubble.animation == "air":
				$Bubble.play("bigPop")
				set_physics_process(false)
				$BubbleCollect/CollisionShape2D.disabled = true
			else:
				queue_free()

# player collect bubble
func _on_BubbleCollect_body_entered(body):
	if !body.ground and $Bubble.frame >= 6:
		body.airTimer = body.defaultAirTime
		body.sfx[23].play()
		body.animator.play("air")
		body.animator.queue("walk")
		body.movement = Vector2.ZERO
		$Bubble.play("bigPop")
		$BubbleCollect/CollisionShape2D.disabled = true
		set_physics_process(false)
