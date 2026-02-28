class_name TargetTracker extends Area2D

## Maximum number of objects the tracker can track at a time. If more objects than this are in the
## area, they will be erased starting from the oldest entry
@export var max_tracked := 8

## How many points are awarded for being under the preferred distance
@export var distance_max_points := 100.0

## If at or below this distance (in pixels), max points are awarded
@export var distance_best_len := 80.0

## If above this distance (in pixels), no points are awarded
@export var distance_worst_len := 200.0

## If the angle from the tracking origin to the target matches the requested target angle exactly,
## this many points will be rewarded. The number of points rewarded drops linearly to zero as the
## difference between the desired angle and the actual angle increases to angle_worst.
@export var angle_max_points := 100.0

## If angle difference is above this value (in radians), no points are awarded
## Defaults to PI / 3.0 (IE 60 degrees)
@export var angle_worst := PI / 3.0

## This many points are automatically awarded to the previous winner to make the tracker less
## likely to quickly swap back and forth between targets when scores are close
@export var incumbent_bonus_points := 40.0

var cur_tracked : Array[Targetable] = []

var last_winner : Targetable = null


## Which target types a target tracker tracks. See Targetable.gd enum TARGETABLE_TAGS for a
## description of each flag to track.
@export_flags("Interactive", "Enemy", "Destructible") var target_tags: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func calc_distance_points(origin: Vector2, target: Targetable) -> float:
	var distance := origin.distance_to(target.global_position)
	
	# If at or below best distance, award max points
	if distance <= distance_best_len:
		return distance_max_points
	
	# If at or above worst distance, award no points
	if distance >= distance_worst_len:
		return 0.0
	
	# Linear interpolation between best and worst
	var t := (distance - distance_best_len) / (distance_worst_len - distance_best_len)
	return distance_max_points * (1.0 - t)


func calc_angle_points(origin: Vector2, direction: Vector2, target: Targetable) -> float:
	# Calculate the vector from origin to target
	var to_target := (target.global_position - origin).normalized()
	
	# Calculate the angle difference between the desired direction and actual direction to target
	var angle_diff : float = abs(direction.angle_to(to_target))
	
	# If angle difference is at or above worst angle, award no points
	if angle_diff >= angle_worst:
		return 0.0
	
	# Linear interpolation from max points at 0 difference to 0 points at angle_worst
	var t :float = angle_diff / angle_worst
	return angle_max_points * (1.0 - t)

## Calculates the scores for each 
func calc_scores(origin: Vector2, direction: Vector2) -> Targetable:
	var highest_score = -100.0
	var highest_index = 0
	
	if cur_tracked.size() == 0:
		return null
	
	for i in range(cur_tracked.size()):
		var this_score := calc_distance_points(origin, cur_tracked[i])
		this_score += calc_angle_points(origin, direction, cur_tracked[i])
		if cur_tracked[i] == last_winner:
			this_score += incumbent_bonus_points
			
		if this_score > highest_score:
			highest_score = this_score
			highest_index = i
			
		if !is_instance_valid(cur_tracked[i]):
			# We'll remove the entity from the list if it was in here and isn't valid anymore.
			call_deferred("_on_body_exited", cur_tracked[i])
	
	last_winner = cur_tracked[highest_index]
	return cur_tracked[highest_index]

func _on_body_entered(body: Node2D) -> void:
	if cur_tracked.size() >= max_tracked:
		return
		
	if body is not Targetable:
		return
		
	var target: Targetable = body
	cur_tracked.append(target)
	

func _on_body_exited(body: Node2D) -> void:
	if body is not Targetable:
		return
	
	cur_tracked.erase(body)
