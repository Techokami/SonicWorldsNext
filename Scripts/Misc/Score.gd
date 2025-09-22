class_name Score extends Node2D

const SCORE: Array[int] = [10,100,200,500,1000,10000]
const RECTS: Array[Rect2] = [
# 10
	Rect2(Vector2(0, 0),  Vector2(10, 8)),
# 100
	Rect2(Vector2(0, 0),  Vector2(15, 8)),
# 200
	Rect2(Vector2(0, 8),  Vector2(15, 8)),
# 500
	Rect2(Vector2(0, 18), Vector2(15, 8)),
# 1000
	Rect2(Vector2(0, 0),  Vector2(20, 8)),
# 10000
	Rect2(Vector2(0, 0),  Vector2(25, 8))
]

var score_id: int = 0

var y_speed: float = -3.0

## Creates a Score object.[br]
## [param parent] - parent object the score will be attached to.[br]
## [param global_pos] - coordinates to create the Score object at
##                      ([b]not[/b] relative to the [param parent]'s coordinates).[br]
## [param _score_id] - index for the score value in the [constant SCORE] array.
static func create(parent: Node, global_pos: Vector2 = parent.global_position, _score_id: int = 0) -> Score:
	var score: Score = preload("res://Entities/Misc/Score.tscn").instantiate()
	score.score_id = _score_id
	parent.add_child(score)
	score.global_position = global_pos
	return score

func _ready():
	# check if adding score would hit the life bonus
	Global.check_score_life(SCORE[score_id])
	
	# add score
	Global.score += SCORE[score_id]
	# set sprite region to match (see RECTS for texture regions
	$Sprite2D.region_rect = RECTS[score_id]

func _physics_process(delta):
	# move score
	y_speed += 0.09375 * 60.0 * delta
	translate(Vector2(0, y_speed * 60.0 * delta))
	if y_speed >= 0:
		queue_free()
