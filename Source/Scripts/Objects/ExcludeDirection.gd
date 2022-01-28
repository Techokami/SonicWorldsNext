extends StaticBody2D
@export_enum( "floor", "ceiling", "left wall", "right wall")var direction = 0
var angleException = Vector2.RIGHT;

func _ready():
	print(Vector2.UP.angle())
	print(Vector2.DOWN.angle())
	print(Vector2.LEFT.angle())
	print(Vector2.RIGHT.angle())
	match(direction):
		1:
			angleException = Vector2.LEFT
		2:
			angleException = Vector2.DOWN
		3:
			angleException = Vector2.UP
