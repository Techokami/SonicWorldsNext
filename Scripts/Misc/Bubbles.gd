class_name Bubble extends Node2D

const _INITIAL_VELOCITY = Vector2(1.0, -32.0)

enum BUBBLE_TYPES { SMALL, MEDIUM, BIG }
var bubble_type: BUBBLE_TYPES = BUBBLE_TYPES.SMALL

var velocity = _INITIAL_VELOCITY
@onready var offset_time = randf_range(0.0, 4.0)
var max_distance: float = 0.0

## Called when the bubble gets inhaled by a player.
signal inhaled(by_player: PlayerChar)

## Generates a small bubble.[br]
## [param parent] - parent object the bubble will be attached to.[br]
## [param _global_position] - coordinates to create the bubble at
##                            ([b]not[/b] relative to the [param parent]'s coordinates).[br]
## [param impulse] - value to add to the initial [member velocity] of the bubble.[br]
## [param _max_distance] - maximum Y coordinate (global) the bubble travels upwards to
##                         before popping up by itself ([code]0.0[/code] means no maximum distance.[br]
## [param _z_index] - display priority (see [member CanvasItem.z_index];
##                    assumed to be [code]parent.z_index[/code] by default).
static func create_small_bubble(parent: Node, _global_position: Vector2, impulse: Vector2 = Vector2.ZERO, _max_distance: float = 0.0, _z_index: int = parent.z_index) -> Bubble:
	return _create_bubble(parent, _global_position, impulse, _max_distance, _z_index, BUBBLE_TYPES.SMALL)

## Randomly generates a small or medium bubble, based on specified distribution.[br]
## [param parent] - parent object the bubble will be attached to.[br]
## [param _global_position] - coordinates to create the bubble at
##                            ([b]not[/b] relative to the [param parent]'s coordinates).[br]
## [param impulse] - value to add to the initial [member velocity] of the bubble.[br]
## [param _max_distance] - maximum Y coordinate (global) the bubble travels upwards to
##                         before popping up by itself ([code]0.0[/code] means no maximum distance.[br]
## [param _z_index] - display priority (see [member CanvasItem.z_index];
##                    assumed to be [code]parent.z_index[/code] by default).[br]
## [param distribution] - probability of random generation of small or medium bubbles:[br]
##                        ○ if [code]distribution = 0.0[/code], the function will always generate a small bubble,[br]
##                        ○ [code]distribution = 1.0[/code] makes the function always generate a medium bubble, and[br]
##                        ○ [code]distribution = 0.5[/code] means a ~50/50 chance of generating either small or medium bubble.
static func create_small_or_medium_bubble(parent: Node, _global_position: Vector2, impulse: Vector2 = Vector2.ZERO, _max_distance: float = 0.0, _z_index: int = parent.z_index, distribution: float = 0.5) -> Bubble:
	var type: BUBBLE_TYPES = BUBBLE_TYPES.MEDIUM if randf() + distribution > 1.0 else BUBBLE_TYPES.SMALL
	return _create_bubble(parent, _global_position, impulse, _max_distance, _z_index, type)

## Generates a big bubble that can be inhaled by players.[br]
## [param parent] - parent object the bubble will be attached to.[br]
## [param _global_position] - coordinates to create the bubble at
##                            ([b]not[/b] relative to the [param parent]'s coordinates).[br]
## [param impulse] - value to add to the initial [member velocity] of the bubble.[br]
## [param _max_distance] - maximum Y coordinate (global) the bubble travels upwards to
##                         before popping up by itself ([code]0.0[/code] means no maximum distance.[br]
## [param _z_index] - display priority (see [member CanvasItem.z_index];
##                    assumed to be [code]parent.z_index[/code] by default).
static func create_big_bubble(parent: Node, _global_position: Vector2, impulse: Vector2 = Vector2.ZERO, _max_distance: float = 0.0, _z_index: int = parent.z_index) -> Bubble:
	return _create_bubble(parent, _global_position, impulse, _max_distance, _z_index, BUBBLE_TYPES.BIG)

static func _create_bubble(parent: Node, _global_position: Vector2, impulse: Vector2, _max_distance: float, _z_index: int, bub_type: BUBBLE_TYPES) -> Bubble:
	var bubble: Bubble = preload("res://Entities/Misc/Bubbles.tscn").instantiate()
	bubble.bubble_type = bub_type
	bubble.z_index = _z_index
	bubble.velocity = _INITIAL_VELOCITY + impulse
	bubble.max_distance = _max_distance
	parent.add_child(bubble)
	bubble.global_position = _global_position
	return bubble

func _ready():
	$Bubble.frame = 0
	match bubble_type:
		BUBBLE_TYPES.SMALL:
			$Bubble.play("default")
		BUBBLE_TYPES.MEDIUM:
			$Bubble.play("medium")
		BUBBLE_TYPES.BIG:
			$Bubble.play("air")
			$BubbleCollect/CollisionShape2D.disabled = false

# queue if popped
func _on_Bubble_animation_finished():
	if $Bubble.animation == "bigPop":
		queue_free()

func _physics_process(delta):
	# check if the bubble is big and it collides with any players
	if bubble_type == BUBBLE_TYPES.BIG and $Bubble.animation == "air" and $Bubble.frame >= 6:
		var players: Array[Node2D] = $BubbleCollect.get_overlapping_bodies()
		if players.size() != 0:
			# get the first PlayerChar body the bubble collides with
			for player: PlayerChar in players:
				if !player.ground and player.get_shield() != player.SHIELDS.BUBBLE:
					player.airTimer = player.defaultAirTime
					player.sfx[23].play()
					player.set_state(player.STATES.AIR)
					player.get_avatar().get_animator().play("air")
					player.get_avatar().get_animator().queue("walk")
					player.movement = Vector2.ZERO
					$Bubble.play("bigPop")
					$BubbleCollect/CollisionShape2D.set_deferred("disabled", true)
					set_physics_process(false)
					inhaled.emit(player)
					break
	
	# check if below water level and rise
	if Global.waterLevel != null:
		if global_position.y > Global.waterLevel and (global_position.y > max_distance or max_distance == 0):
			translate(velocity*delta)
			offset_time += delta
			velocity.x = cos(offset_time*4)*8
			# slow down y velocity if approaching max distance
			if max_distance != 0:
				if abs(max_distance-global_position.y) < abs(velocity.y/2.0):
					velocity.y = min(_INITIAL_VELOCITY.y,(max_distance-global_position.y)*2.0)
		else:
			# if big bubble then play popping animation
			if $Bubble.animation == "air":
				$Bubble.play("bigPop")
				set_physics_process(false)
				$BubbleCollect/CollisionShape2D.disabled = true
			else:
				queue_free()

# clear if off screen
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
