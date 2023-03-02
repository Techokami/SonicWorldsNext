extends Node2D
@tool

# this moves back and forth based on a timer and speed, direction is angle based
@export var distance = 64
@export var wait = 1.0
var timer = wait
var extend = false

func _process(delta):
	# timer
	if !Engine.is_editor_hint():
		if timer > 0:
			timer -= delta
		else:
			timer = wait
			extend = !extend
	else:
		queue_redraw()

func _physics_process(delta):
	if !Engine.is_editor_hint():
		$CrushBox.position = $CrushBox.position.move_toward((Vector2(0,distance*int(extend))*$CrushBox.scale),768*delta)

func _draw():
	if Engine.is_editor_hint():
		var offset = Vector2(-$CrushBox/Crusher.texture.get_width()/2,-$CrushBox/Crusher.texture.get_height()/2)+$CrushBox/Crusher.offset
		draw_texture($CrushBox/Crusher.texture,(Vector2(0,distance)*$CrushBox.scale)+offset,Color(1,0.5,0.5,0.5))
