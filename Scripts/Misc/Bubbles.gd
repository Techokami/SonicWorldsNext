class_name Bubble extends Node2D

static var _bubble_scene = preload("res://Entities/Misc/Bubbles.tscn")

enum BUBBLE_TYPES {SMALL,MEDIUM,AIR_BUBBLE}
var bubble_type: BUBBLE_TYPES = BUBBLE_TYPES.SMALL

signal inhaled(by_player: PlayerChar)

static var DEFAULT_VELOCITY = Vector2(1.0, -32.0)
var velocity = DEFAULT_VELOCITY
@onready var offset_time = randf()*4
var max_distance:float = 0.0

## Generates a small air bubble.
static func create_small_bubble(parent: Node, _position: Vector2, impulse: Vector2 = Vector2.ZERO, _max_distance: float = 0.0, _z_index: int = 0) -> Bubble:
	return _create_bubble(parent, _position, impulse, _max_distance, _z_index, BUBBLE_TYPES.SMALL)

## Generates a small or medium air bubble, ased on granularity (0.0 means always generating small
## bubbles, 1.0 means always generating medium bubbles, 0.5 - a 50/50 chance between small and medium).
static func create_small_or_medium_bubble(parent: Node, _position: Vector2, impulse: Vector2 = Vector2.ZERO, _max_distance: float = 0.0, _z_index: int = 0, granularity: float = 0.5) -> Bubble:
	var type: BUBBLE_TYPES = BUBBLE_TYPES.MEDIUM if randf() + granularity > 1.0 else BUBBLE_TYPES.SMALL
	return _create_bubble(parent, _position, impulse, _max_distance, _z_index, type)

## Generates a big (breathable) air bubble.
static func create_air_bubble(parent: Node, _position: Vector2, impulse: Vector2 = Vector2.ZERO, _max_distance: float = 0.0, _z_index: int = 0) -> Bubble:
	return _create_bubble(parent, _position, impulse, _max_distance, _z_index, BUBBLE_TYPES.AIR_BUBBLE)

static func _create_bubble(parent: Node, _position: Vector2, impulse: Vector2, _max_distance: float, _z_index: int, bub_type: BUBBLE_TYPES) -> Bubble:
	var bubble: Bubble = _bubble_scene.instantiate()
	parent.add_child(bubble)
	bubble.global_position = _position
	bubble.velocity = DEFAULT_VELOCITY + impulse
	bubble.max_distance = _max_distance
	bubble.z_index = _z_index
	bubble.bubble_type = bub_type
	return bubble

func _ready():
	$Bubble.frame = 0
	match(bubble_type):
		BUBBLE_TYPES.SMALL:
			$Bubble.play("default")
		BUBBLE_TYPES.MEDIUM:
			$Bubble.play("medium")
		BUBBLE_TYPES.AIR_BUBBLE:
			$Bubble.play("air")
			$BubbleCollect/CollisionShape2D.disabled = false

# queue if popped
func _on_Bubble_animation_finished():
	if $Bubble.animation == "bigPop":
		queue_free()

func _physics_process(delta):
	# check if below water level and rise
	if Global.waterLevel != null:
		if global_position.y > Global.waterLevel and (global_position.y > max_distance or max_distance == 0):
			translate(velocity*delta)
			offset_time += delta
			velocity.x = cos(offset_time*4)*8
			# slow down y velocity if approaching max distance
			if max_distance != 0:
				if abs(max_distance-global_position.y) < abs(velocity.y/2.0):
					velocity.y = min(-32,(max_distance-global_position.y)*2.0)
		else:
			# if big bubble then play popping animation
			if $Bubble.animation == "air":
				$Bubble.play("bigPop")
				set_physics_process(false)
				$BubbleCollect/CollisionShape2D.disabled = true
			else:
				queue_free()

# player collect bubble
func _on_BubbleCollect_body_entered(body):
	# player get air, ignore if they're already in a bubble
	if !body.ground and $Bubble.frame >= 6 and body.shield != body.SHIELDS.BUBBLE:
		body.airTimer = body.defaultAirTime
		body.sfx[23].play()
		
		body.set_state(body.STATES.AIR)
		body.animator.play("air")
		body.animator.queue("walk")
		body.movement = Vector2.ZERO
		$Bubble.play("bigPop")
		$BubbleCollect/CollisionShape2D.call_deferred("set","disabled",true)
		set_physics_process(false)
		inhaled.emit(body)

# clear if off screen
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
