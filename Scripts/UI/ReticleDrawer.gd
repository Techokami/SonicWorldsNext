@tool
class_name ReticleDrawerHuman extends Node2D

## The number of arc segments to be drawn -- the circle will be split into this many arcs
@export_range(1,32) var arc_segments := 3:
	set(value):
		arc_segments = value
		_set_gaps()
		queue_redraw()

## Current radius of the arc in pixels
@export var arc_radius := 20.0:
	set(value):
		arc_radius = value
		queue_redraw()

## The percentage of the circle that is gaps between the arc segments
@export_range(0, 100) var gap_percentage := 30.0:
	set(value):
		gap_percentage = value
		_set_gaps()
		queue_redraw()

## Thickness of the arcs
@export var arc_thickness := 5.0:
	set(value):
		arc_thickness = value
		queue_redraw()

## Current rotation of the reticle (rotation offset for all arc segments)
@export_range(-4*PI, 4*PI) var reticle_rotation := 0.0:
	set(value):
		reticle_rotation = value
		queue_redraw()

## Color of the reticle
@export var reticle_color := Color.WHITE:
	set(value):
		reticle_color = value
		queue_redraw()

## Number of points per arc (higher = smoother)
@export var arc_resolution := 16:
	set(value):
		arc_resolution = max(3, value)
		queue_redraw()

## Enable the arc segments
@export var draw_arc_segments := true:
	set(value):
		draw_arc_segments = value
		queue_redraw()

## Enable drawing triangles in gaps
@export var draw_gap_triangles := true:
	set(value):
		draw_gap_triangles = value
		queue_redraw()

## Offset from arc radius where the triangle base is positioned
@export var triangle_base_offset := 10.0:
	set(value):
		triangle_base_offset = value
		queue_redraw()

## Percentage of gap width that the triangle base should occupy
@export_range(0, 100) var triangle_width_percentage := 40.0:
	set(value):
		triangle_width_percentage = value
		queue_redraw()

## Scrapping triangle_width_percentage for triangle_angle -- determines the angle of the 
@export_range(PI / 60, PI) var triangle_angle := PI / 8:
	set(value):
		triangle_angle = value
		queue_redraw()

## Height of the gap triangles (distance from base radius inward toward center)
@export var triangle_height := 20.0:
	set(value):
		triangle_height = value
		queue_redraw()

## Scrapping triangle_height for triangle_leg_length
@export var triangle_leg_length := 20.0:
	set(value):
		triangle_leg_length = value
		queue_redraw()

## Rotation offset for triangles in degrees (allows triangles to be drawn off-center from gaps)
@export_range(-4*PI, 4*PI) var triangle_rotation_offset := 0.0:
	set(value):
		triangle_rotation_offset = value
		queue_redraw()

## If true, triangles are drawn on top of arcs. If false, arcs are drawn on top of triangles.
@export var triangles_on_top := true:
	set(value):
		triangles_on_top = value
		queue_redraw()

## Color of the gap triangles
@export var triangle_color := Color.WHITE:
	set(value):
		triangle_color = value
		queue_redraw()

var rads_per_arc_segment = 2 * PI / arc_segments
var rads_per_gap = rads_per_arc_segment * (gap_percentage / 100.0)
var rads_per_arc = rads_per_arc_segment - rads_per_gap

# Sets up gap angles - needed when something changes that would impact the gap angles such as
# gap percentages or number of segments
func _set_gaps():
	rads_per_arc_segment = 2 * PI / arc_segments
	rads_per_gap = rads_per_arc_segment * (gap_percentage / 100.0)
	rads_per_arc = rads_per_arc_segment - rads_per_gap

func _draw_arcs():
	if !draw_arc_segments:
		return
	# angle starts from the top -- left/right symmetry is favored
	var start_offset = (-PI / 2) + (rads_per_gap / 2) + reticle_rotation
	
	for i in range(arc_segments):
		var start_angle = i * rads_per_arc_segment + start_offset
		var end_angle = start_angle + rads_per_arc
		draw_arc(Vector2.ZERO, arc_radius, start_angle, end_angle, arc_resolution / arc_segments, reticle_color, arc_thickness, false)
	
	pass
	
func _draw_triangles():
	if !draw_gap_triangles:
		return
	var start_offset = (-PI / 2)
	for i in range(arc_segments):
		var point_angle = i * rads_per_arc_segment + start_offset + reticle_rotation + triangle_rotation_offset
		var point1 = Vector2.ZERO + Vector2.from_angle(point_angle) * (arc_radius + triangle_base_offset)
		var leg_angle_1 = point_angle + 0.5 * triangle_angle
		var point2 = point1 + Vector2.from_angle(leg_angle_1) * triangle_leg_length
		var leg_angle_2 = point_angle - 0.5 * triangle_angle
		var point3 = point1 + Vector2.from_angle(leg_angle_2) * triangle_leg_length
		var points = PackedVector2Array([point1, point2, point3])
		draw_colored_polygon(points, triangle_color)
	
func _draw():
	if triangles_on_top:
		_draw_arcs()
		_draw_triangles()
	else:
		_draw_triangles()
		_draw_arcs()
	pass
