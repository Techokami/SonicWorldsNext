extends StaticBody2D
export (int, "floor", "ceiling", "left wall", "right wall")var direction = 0
var angleException = Vector2.RIGHT;

func _ready():
	match(direction):
		1:
			angleException = Vector2.LEFT
		2:
			angleException = Vector2.DOWN
		3:
			angleException = Vector2.UP
