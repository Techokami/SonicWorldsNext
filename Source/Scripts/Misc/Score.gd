extends Node2D

const SCORE = [10,100,200,500,1000,10000]
const RECTS = [Rect2(Vector2(0,0),Vector2(10,8)),Rect2(Vector2(0,0),Vector2(15,8)),Rect2(Vector2(0,8),Vector2(15,8)),
Rect2(Vector2(0,18),Vector2(15,8)),Rect2(Vector2(0,0),Vector2(20,8)),Rect2(Vector2(0,0),Vector2(25,8))]

var scoreID = 0

var yspeed = -3

func _ready():
	Global.check_score_life(SCORE[scoreID])
	
	Global.score += SCORE[scoreID]
	$Sprite.region_rect = RECTS[scoreID]
	

func _physics_process(delta):
	yspeed += 0.09375*60*delta
	translate(Vector2(0,yspeed*60*delta))
	if yspeed >= 0:
		queue_free()
