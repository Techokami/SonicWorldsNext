@tool
extends Node2D

## How far the end of the chain is from its ceiling initially
## (travels here after receiving return_chain signal)
@export_range(0,2000) var initial_height: int = 100

## Default distance the far end of the chain should be from its ceiling
## (travels here after receiving move_chain signal)
@export_range(0,2000) var default_target_height: int = 200

## How many pixels per reference time should the chain should move to reach
## its target height (going upwards only -- you probably want to keep these the
## same)
@export_range(0,400) var chain_speed_up: int = 150

## How many pixels per reference time should the chain should move to reach
## its target height (going down only -- you probably want to keep these the
## same)
@export_range(0,400) var chain_speed_down: int = 150

## What texture to use for the chain
@export var link_texture: Texture2D = preload("res://Graphics/Gimmicks/FBZMonkeyBarLink.png")

## What's at the end of the chain that this thing is moving?
## For instance, it could be a monkey bar! Or a circular saw. Whatever you like.
## This should be something in the same scene as your chain
@export var end_of_chain: Node2D = null

## This signal is emitted when the chain's default target is reached
## (does not emit on reaching return home target)
## (does not emit on reaching target set via set_target_height(int) unless
##  default_target_height is also set to the same value)
## This signal is useful for using the chain reaching its destination as a
## switch
signal target_reached

## This signal is emitted when the chain reaches its initial height
## You can use this with a slow chain speed to do things similar to the
## Sandopolis Zone door switches, but with hangers on chains instead.
signal home_reached

## This signal is emitted if a target was reached and it was neither
## The initial height or the default target height. Basically only expect
## to see this if you are changing the target height (but not the default
## target height) with set_target_height(new_target_height)
signal custom_reached

## This signal is emitted if the chain starts moving.
signal chain_started_moving

## This signal is emitted if the chain stops moving.
signal chain_stopped_moving

var target_height = 6
var cur_height : float = 6.0
var moving = false

# What a horrendous amount of effort to draw a triangle in for editor mode...
var down_arrow_cords : Array = [
	[-4, -pow(3, 0.5) * 4], [4, -pow(3, 0.5) * 4], [0, 0]
]
var down_arrow : PackedVector2Array
# If I were a more intelligent man, I probably could transform the other one
# as needed.
var up_arrow_cords : Array = [
	[-4, (pow(3, 0.5) * 4)], [4, (pow(3, 0.5) * 4)], [0, 0]
]
var up_arrow : PackedVector2Array

func float_array_to_Vector2Array(coords : Array) -> PackedVector2Array:
	# Convert the array of floats into a PackedVector2Array.
	var array : PackedVector2Array = []
	for coord in coords:
		array.append(Vector2(coord[0], coord[1]))
	return array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cur_height = initial_height
	target_height = initial_height
	down_arrow = float_array_to_Vector2Array(down_arrow_cords)
	up_arrow = float_array_to_Vector2Array(up_arrow_cords)
	pass # Replace with function body.
	
func set_height_at_target():
	cur_height = target_height
	moving = false
	chain_stopped_moving.emit()
	
	if target_height == default_target_height:
		target_reached.emit()
	elif target_height == initial_height:
		home_reached.emit()
	else:
		custom_reached.emit()
	
func _physics_process(delta: float) -> void:
	# Don't run it if in the editor.
	if Engine.is_editor_hint():
		return
		
	# If the chain isn't moving, we don't need to do squat.
	if cur_height == target_height:
		return
	
	# Track if te chain started moving and emit signal to anyone who cares
	if !moving:
		moving = true
		chain_started_moving.emit()

	# Move the current height and if we go past the target, we need to fix that.
	if cur_height > target_height:
		cur_height -= chain_speed_up * delta
		if cur_height <= target_height:
			set_height_at_target()
	elif cur_height < target_height:
		cur_height += chain_speed_down * delta
		if cur_height >= target_height:
			set_height_at_target()

	# If we have something on the end of the chain, we need to move it.
	if end_of_chain != null:
		end_of_chain.position.y = cur_height

func process_tool():
	queue_redraw()
	if end_of_chain != null:
		end_of_chain.position = Vector2(0, initial_height)
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		process_tool()
		return
		
	queue_redraw()

# Colors used to draw hint arrows for the default target
var up_color = Color.CRIMSON
var down_color = Color.DARK_BLUE
	
func draw_tool():
	var hint_color
	var hint_arrow
	var line_cutter

	if initial_height > default_target_height:
		hint_color = up_color
		hint_arrow = up_arrow
		line_cutter = 2
	else:
		hint_color = down_color
		hint_arrow = down_arrow
		line_cutter = -2
	
	for n in range(initial_height, 0, -link_texture.get_height()):
		draw_texture(link_texture, Vector2(-link_texture.get_width() / 2.0, n - link_texture.get_height()))
	
	# Don't draw hints unless they are far enough from origin to make it worthwhile.
	if (abs(initial_height - default_target_height)) > 8:
		draw_line(Vector2(0,initial_height), Vector2(0, default_target_height + line_cutter), hint_color, 2.0)
		# Move the draw transform so that we can draw the arrow
		draw_set_transform(Vector2(0, default_target_height))
		draw_polygon(hint_arrow, [hint_color])

func _draw():
	if Engine.is_editor_hint():
		return draw_tool()

	for n in range(cur_height, 0, -link_texture.get_height()):
		draw_texture(link_texture, Vector2(-link_texture.get_width() / 2.0, n - link_texture.get_height()))
		
## Sets the home destination of the chain
func set_home_height(new_home_height):
	initial_height = new_home_height

## Sets the default target height.
func set_default_target(new_target_height):
	default_target_height = new_target_height

## Sets the destination to home
func send_home():
	target_height = initial_height

## Sets the destination to the default target height
func send_to_default_target():
	target_height = default_target_height

## Sets the destination to any given height
func send_to_height(new_target_height):
	target_height = new_target_height
