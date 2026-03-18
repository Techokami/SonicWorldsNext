## A basic building block of every zoom tube that defines the path the player
## travels through. Can be optionally provided with a texture to draw.[br]
## After placing a tube, connect two joints (of type [ZoomTubeConnector]
## or [ZoomTubeEnd]) to it from their [member ZoomTubeEnd.connected_to]
## variables.[br]
## Authors: Stanislav Gromov, DimensionWarped.[br]
## Thanks to:[br]
## * Renhoex - original zoom tube implementation (although the current one
##   is a full rewrite).
@tool
class_name ZoomTube extends Path2D


static var _curves: Dictionary = {} # TODO: Use a typed dictionary when we upgrade to Godot 4.4 or later


## The texture used for the tube (drawn as a polyline).
@export var texture: Texture2D = null:
	set(new_texture):
		texture = new_texture
		if new_texture != null and _line == null:
			_line = Line2D.new()
			add_child(_line)
		_line.texture = new_texture

## Speed of traveling through the tube.
@export var speed: float = 8.0

## How many degrees to pass to tesselate for the sake of setting curve segment.
@export_range(2.0, 90.0) var tesselation_tolerance: float = 4.0:
	set(value):
		tesselation_tolerance = value
		_rebuild_line()

## Maximum number of subdivisions to tesselate with.
@export_range(1, 10) var tesselation_max_stages: int = 5:
	set(value):
		tesselation_max_stages = value
		_rebuild_line()


# Internal class that does all the work of handling the player interaction.
class _ZoomTubeWorker extends ZoomTubeBase:
	func accept_player(player: PlayerChar, end_idx: int) -> void:
		var follower: PathFollow2D = player.get_gimmick_var(_PATH_FOLLOWER_GIMMICK_VAR)
		if follower == null:
			follower = PathFollow2D.new()
			follower.loop = false # don't wrap the progress back to 0 when it overflows
			follower.rotates = false # don't spend CPU time on rotating this node along the path
		
		# detach the path follower from the previous tube, if there's any
		var parent: Node = follower.get_parent()
		if parent != null:
			parent.remove_child(follower)
		
		# now attach it to the current tube
		parent = get_parent()
		parent.add_child(follower)
		follower.progress_ratio = float(end_idx) # 0.0 if (end_idx == 0) else 1.0
		
		player.set_gimmick_var(_PATH_FOLLOWER_GIMMICK_VAR, follower)
		player.set_gimmick_var(_TRAVEL_DIRECTION_GIMMICK_VAR, not end_idx)
	
	func player_physics_process(player: PlayerChar, delta: float) -> void:
		var tube: ZoomTube = get_parent() as ZoomTube
		var follower: PathFollow2D = player.get_gimmick_var(_PATH_FOLLOWER_GIMMICK_VAR)
		var direction: int = player.get_gimmick_var(_TRAVEL_DIRECTION_GIMMICK_VAR)
		follower.progress += tube.speed * delta * 60.0 * (1.0 if direction != 0 else -1.0)
		player.global_position = follower.global_position
		
		if follower.progress_ratio >= 1.0 if direction != 0 else follower.progress_ratio <= 0.0:
			tube._connected_to[direction].accept_player_from_tube(player, tube)


# Array (2 elements) of tube joints connected to this tube from both ends.[br]
# This array isn't exported, as you're supposed to connect tube joints
# (end objects and connectors) to this tube, so they will call this tube's
# [method connect_to] to connect the tube back to them.
var _connected_to: Array[ZoomTubeJoint] = [null, null]

# Used internally to track if the curve has been changed
# and rebuild the corresponding Line2D.
var _curve_mem: Curve2D
var _points_mem: PackedVector2Array = PackedVector2Array()

# Used internally to draw the tube texture as a polyline.
var _line: Line2D = null

# Contains the worker object that handles the player interaction.
var _worker: _ZoomTubeWorker = null


## Connects the tube to the specified [ZoomTubeJoint]. If only one of the ends
## is connected and the other one is free, the onoccupied end is picked
## for connection. Otherwise, if both ends are connected or both are free,
## the closest one to the joint is picked.[br]
## * [param joint] - joint to connect to.
## * [param connection_point] - global position of the point the tube should be
## connected to.
## Returns: The index of the tube's end that got connected.
func connect_to_joint(joint: ZoomTubeJoint, connection_point: Vector2) -> int:
	var end_points: Array[Vector2] = _get_end_points()
	var closest_end_idx: int
	
	if (_connected_to[0] != null) != (_connected_to[1] != null):
		# if only one of the ends is connected and the other one
		# is free, pick the end that's not connected to anything
		closest_end_idx = int(_connected_to[0] != null)
	else:
		# otherwise both ends are connected (or both are unoccupied),
		# so we have to pick the closest one
		closest_end_idx = int(connection_point.distance_to(end_points[0]) > connection_point.distance_to(end_points[1]))
	
	# connect the new joint
	if _connected_to[closest_end_idx] != null:
		_connected_to[closest_end_idx].disconnect_from_tube(self)
	_connected_to[closest_end_idx] = joint
	
	# don't rebuild child Path2D and Line2D nodes in-game,
	# so it won't affect level loading time
	if Engine.is_editor_hint():
		# update the in and out coordinates of the first and last points respectively
		curve.set_point_position(
			0 if closest_end_idx == 0 else (curve.point_count - 1),
			to_local(joint.global_position))
	
	# update custom warnings
	_force_configuration_warnings_update()
	
	return closest_end_idx

## Disconnects the tube from a previously connected joint.[br]
## * [param joint] - joint to disconnect from.
func disconnect_from_joint(joint: ZoomTubeJoint) -> void:
	var end_idx: int = _connected_to.find(joint)
	assert(end_idx != -1)
	_connected_to[end_idx] = null
	_force_configuration_warnings_update()

## Sets the position of the specified end of the tube.[br]
## * [param end_idx] - index of the end.[br]
## * [param point1] - desired global position of the end point.[br]
## * [param point2] - desired global position of the point that comes before the end point.
func set_end_position(end_idx: int, point1: Vector2, point2: Vector2) -> void:
	point1 = to_local(point1)
	point2 = to_local(point2)
	if end_idx == 0:
		curve.set_point_position(0, point1)
		curve.set_point_position(1, point2)
	else:
		curve.set_point_position(curve.point_count - 1, point1)
		curve.set_point_position(curve.point_count - 2, point2)

## Accepts the player from a joint the tube is connected to.[br]
## * [param player] - player to accept into the tube.[br]
## * [param end_idx] - index of the tube end the player starts traveling from.[br]
## * [param play_sound] - whether to play the spin sound.
func accept_player(player: PlayerChar, end_idx: int, play_sound: bool = true) -> void:
	player.global_position = \
		to_global(curve.get_point_position(0 if end_idx == 0 else curve.point_count - 1))
	player.movement = Vector2.ZERO
	
	if play_sound:
		player.sfx[1].play()
	
	# unset the joint first, so its `player_force_detach_callback()` won't get called
	player.unset_active_gimmick()
	
	player.set_active_gimmick(_worker)
	_worker.accept_player(player, end_idx)


func _ready() -> void:
	# when the tube gets copied in the editor, the child Line2D node
	# gets copied along with it, so we need to find it
	if texture != null or Engine.is_editor_hint():
		for n: Node in get_children():
			if n is Line2D:
				_line = n
				break
		
		# if we couldn't find the line node, then it means the tube
		# is newly created, not copied, so we need to create a new line
		if _line == null:
			_line = Line2D.new()
			add_child(_line)
		
		_line.texture = texture
		_rebuild_line()
	
	if not Engine.is_editor_hint():
		_worker = _ZoomTubeWorker.new()
		add_child(_worker)
		set_process(false)

func _process(_delta: float) -> void:
	if _is_opened_as_scene():
		return
	
	# recreate the curve if it was removed by the user
	_recreate_curve()
	
	var need_rebuild_line: bool = false
	
	if curve != _curve_mem:
		_curve_mem = curve
		need_rebuild_line = true
	
	if texture != null:
		var points: PackedVector2Array = PackedVector2Array()
		points.resize(curve.point_count * 3)
		for i: int in curve.point_count:
			points[i * 3 + 0] = curve.get_point_position(i)
			points[i * 3 + 1] = curve.get_point_in(i)
			points[i * 3 + 2] = curve.get_point_out(i)
		
		if points != _points_mem:
			need_rebuild_line = true
			_points_mem = points
	
	if need_rebuild_line:
		_rebuild_line()
		_force_configuration_warnings_update()

func _enter_tree() -> void:
	_recreate_curve(true)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		_curves.erase(curve)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if not _is_opened_as_scene():
		if _connected_to.find(null) != -1:
			warnings.append(
				"This tube doesn't have all connections configured.\n" +
				"Consider connecting other tube joints to this tube via their 'connected_to' variable."
			)
		if curve == null:
			warnings.append(
				"This tube has no path configured, so it can't function properly.\n" +
				"Consider adding a curve via the 'curve' variable."
			)
	return warnings

func _is_opened_as_scene() -> bool:
	return get_parent() == get_viewport()

func _get_end_points() -> Array[Vector2]:
	if curve == null or curve.point_count < 2:
		return [global_position, global_position]
	return [
		to_global(curve.get_point_position(0)),
		to_global(curve.get_point_position(curve.point_count - 1))
	]

func _recreate_curve(from_enter_tree: bool = false) -> void:
	if _is_opened_as_scene():
		return
	
	# HACK: when copying a tube in the editor, the new tube gets assigned
	# the same curve, so we need to manually keep track of curves and
	# create a new one for the copied tube
	if Engine.is_editor_hint() and from_enter_tree and curve != null:
		if _curves.has(curve):
			curve = curve.duplicate()
		else:
			_curves[curve] = self
	elif curve == null:
		curve = Curve2D.new()
	
	
	for i in 4 - curve.point_count:
		curve.add_point(Vector2.ZERO)

func _rebuild_line() -> void:
	if _is_opened_as_scene() or _line == null:
		return
	
	if _line.texture == null:
		_line.texture_mode = Line2D.LINE_TEXTURE_NONE
		_line.width = 0
		_line.clear_points()
		return
	
	_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	_line.width = _line.texture.get_height()
	var last_point_idx: int = curve.point_count - 1
	var start_point_mem: Vector2 = curve.get_point_position(0)
	var end_point_mem: Vector2 = curve.get_point_position(last_point_idx)
	curve.set_point_position(0, curve.get_point_position(1))
	curve.set_point_position(last_point_idx, curve.get_point_position(last_point_idx - 1))
	var points: PackedVector2Array = curve.tessellate(tesselation_max_stages, tesselation_tolerance)
	curve.set_point_position(0, start_point_mem)
	curve.set_point_position(last_point_idx, end_point_mem)
	_line.clear_points()
	for i: int in points.size():
		_line.add_point(points[i])

# HACK: Apparently `update_configuration_warnings()` won't call
# `_get_configuration_warnings()`, unless we modify the tree
func _force_configuration_warnings_update() -> void:
	var node: Node = Node.new()
	add_child(node)
	node.free()
	
	update_configuration_warnings()
