@tool

## Controls the rotating star pattern that follows the player when they get an invincibility
## monitor.

class_name InvincibilityBarrier extends Node2D

## The spritesheet texture containing the animation frames.
@export var sprite_texture: Texture2D = preload("res://Graphics/Items/invincible_stars_s2.png"):
	set(val):
		sprite_texture = val
		queue_redraw()

## Total number of horizontal frames in the sprite sheet texture.
@export var h_frames: int = 8

## Duration of each individual animation frame in seconds (defaults to 1/60th of a second).
@export var frame_duration: float = 1.0 / 60.0

## Standard base radius distance at which orbiters rotate around their 
## tracked position history points.
@export var base_radius: float = 17.0

## Global rotation direction for orbiters ([code]true[/code] for clockwise, [code]false[/code] for
## counter-clockwise). Automatically updated by horizontal mouse movement when [member test_mode]
## is active.
@export var right_direction: bool = true

## Array of configuration dictionaries defining each trail/marker level (delay, 
## sprite frame offsets, radius multipliers, orbiter counts, periods, phase offsets, 
## animation index sequences per orbiter, and alpha).
@export var marker_configs: Array[Dictionary] = [
	{ 
		"delay": 0.0, 
		"radius_multiplier": 1.0, 
		"orbiter_count": 2, 
		"orbiter_period": 32.0 / 60.0, 
		"orbiter_offset": 0.0,
		"animation_indices": [
			[7, 4, 6, 4, 4, 6, 4, 7, 4, 6, 6, 4],
			[7, 4, 6, 4, 4, 6, 4, 7, 4, 6, 6, 4]
		],
		"alpha": 1.0,
		"off_frame_phase_offset": PI / 2.0
	},
	{ 
		"delay": (3.0 / 60.0), 
		"radius_multiplier": 1.0, 
		"orbiter_count": 2, 
		"orbiter_period": 32.0 / 60.0, 
		"orbiter_offset": PI / 4.0,
		"animation_indices": [
			[2, 3, 4, 5, 6, 7, 6, 5, 4, 3],
			[7, 6, 5, 4, 3, 2, 3, 4, 5, 6]
		],
		"alpha": 1.0,
		"off_frame_phase_offset": 0.0
	},
	{ 
		"delay": (6.0 / 60.0), 
		"radius_multiplier": 1.0, 
		"orbiter_count": 2, 
		"orbiter_period": 32.0 / 60.0, 
		"orbiter_offset": 2.0 * PI / 4.0,
		"animation_indices": [
			[7, 6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6],
			[1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2]
		],
		"alpha": 1.0,
		"off_frame_phase_offset": 0.0
	},
	{ 
		"delay": (9.0 / 60.0), 
		"radius_multiplier": 1.0, 
		"orbiter_count": 2, 
		"orbiter_period": 32.0 / 60.0, 
		"orbiter_offset": 3.0 * PI / 4.0,
		"animation_indices": [
			[0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1],
			[6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5]
		],
		"alpha": 1.0,
		"off_frame_phase_offset": 0.0
	}
]:
	set(val):
		if val.size() > marker_configs.size():
			var template = {}
			if not marker_configs.is_empty():
				template = marker_configs.back().duplicate(true)
			else:
				template = { 
					"delay": 0.0, 
					"radius_multiplier": 1.0, 
					"orbiter_count": 2, 
					"orbiter_period": 32.0 / 60.0, 
					"orbiter_offset": 0.0,
					"animation_indices": [
						[0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1],
						[0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1]
					],
					"alpha": 1.0,
					"off_frame_phase_offset": 0.0
				}
			
			for i in range(marker_configs.size(), val.size()):
				if val[i].is_empty():
					val[i] = template.duplicate(true)
					
		marker_configs = val
		_sync_all_orbiter_animation_indices()
		if Engine.is_editor_hint():
			_initialize_animation_arrays()

# Used to adjust the default draw pos when running in test mode
var custom_draw_pos: Vector2 = Vector2.ZERO
# Used to track direction when running in test mode
var last_mouse_pos: Vector2 = Vector2.ZERO

# Tracks overall elapsed game time
var accumulated_time: float = 0.0

# Tracks the current animation frame of each circle's effects
var marker_frames: PackedInt32Array = PackedInt32Array()

# Used to mark time accumulated within the marker (needed because each marker can
# set its own period)
var marker_time_accumulators: PackedFloat32Array = PackedFloat32Array()

# Pre-allocated Circular Ring Buffer variables for O(1) writes, O(Log(n)) reads.
# PACKEDVECTOR3ARRAY MAPPING:
# - .x = World Position X (float)
# - .y = World Position Y (float)
# - .z = Timestamp (float)
# Packing both 2D spatial coordinates and time into a single Vector3 eliminates
# dictionary overhead while retaining memory contiguity and fast CPU cache iteration.
const HISTORY_SIZE: int = 300
var position_history: PackedVector3Array = PackedVector3Array()
var write_index: int = 0
var history_count: int = 0

# Enables standalone scene testing (F6) with automatic camera creation and mouse
# tracking.
var test_mode: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint() and get_tree().current_scene == self:
		test_mode = true
		
		var camera = Camera2D.new()
		camera.position = Vector2(0, 0)
		camera.enabled = true
		add_child(camera)
		
	_sync_all_orbiter_animation_indices()
	_initialize_animation_arrays()
		
	# Allocate continuous block of 300 Vector3 instances filled with ZERO
	position_history.resize(HISTORY_SIZE)
	position_history.fill(Vector3.ZERO)
		
	last_mouse_pos = get_local_mouse_position()
	
	top_level = true

## Ensures `animation_indices` in each marker_config matches `orbiter_count`.
## Duplicates the last array entry when expanding, or truncates if shrinking.
func _sync_all_orbiter_animation_indices() -> void:
	for config in marker_configs:
		var target_count: int = config.get("orbiter_count", 2)
		var anim_indices: Array = config.get("animation_indices", [])
		
		if anim_indices.size() == target_count:
			continue
			
		if anim_indices.is_empty():
			# Fallback if entirely empty
			var default_seq: Array = [0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1]
			for k in range(target_count):
				anim_indices.append(default_seq.duplicate())
		elif anim_indices.size() < target_count:
			# Duplicate the last populated array to backfill new orbiters
			var template_seq: Array = anim_indices.back().duplicate()
			while anim_indices.size() < target_count:
				anim_indices.append(template_seq.duplicate())
		elif anim_indices.size() > target_count:
			# Truncate surplus orbiter animations
			anim_indices.resize(target_count)
			
		config["animation_indices"] = anim_indices

func _initialize_animation_arrays() -> void:
	marker_frames.clear()
	marker_time_accumulators.clear()
	
	for config in marker_configs:
		marker_frames.append(0)
		marker_time_accumulators.append(0.0)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	elif !test_mode:
		self.global_position = get_parent().global_position
		
	accumulated_time += delta

	if test_mode:
		var current_mouse_pos = get_local_mouse_position()
		if current_mouse_pos.x != last_mouse_pos.x:
			right_direction = (current_mouse_pos.x > last_mouse_pos.x)
		last_mouse_pos = current_mouse_pos
		custom_draw_pos = current_mouse_pos
	else:
		custom_draw_pos = Vector2.ZERO
	
	record_position_history()
	
	if not sprite_texture or marker_configs.is_empty():
		return
	
	if marker_frames.size() != marker_configs.size():
		_initialize_animation_arrays()
	
	for i: int in range(marker_configs.size()):
		var config = marker_configs[i]
		var anim_sequences: Array = config.get("animation_indices", [])
		if anim_sequences.is_empty() or anim_sequences[0].is_empty():
			continue
			
		marker_time_accumulators[i] += delta
		if marker_time_accumulators[i] >= frame_duration:
			marker_time_accumulators[i] = 0.0
			var seq_len: int = anim_sequences[0].size()
			marker_frames[i] = (marker_frames[i] + 1) % seq_len
					
	queue_redraw()

func record_position_history() -> void:
	var current_time = accumulated_time
	var effective_world_pos = global_position + custom_draw_pos
	
	# Pack (x, y) into Vector3.x and Vector3.y, and store timestamp into Vector3.z
	position_history[write_index] = Vector3(
		effective_world_pos.x,
		effective_world_pos.y,
		current_time
	)
	write_index = (write_index + 1) % HISTORY_SIZE
	
	if history_count < HISTORY_SIZE:
		history_count += 1

## Fetches raw Vector3 record from circular ring buffer
func get_history_item(i: int) -> Vector3:
	var physical_index = (write_index - 1 - i + HISTORY_SIZE) % HISTORY_SIZE
	return position_history[physical_index]

func get_interpolated_position(target_time: float) -> Vector2:
	if history_count == 0:
		return global_position + custom_draw_pos
		
	var newest: Vector3 = get_history_item(0)
	var newest_time: float = newest.z
	if target_time >= newest_time:
		return Vector2(newest.x, newest.y)
		
	var oldest: Vector3 = get_history_item(history_count - 1)
	var oldest_time: float = oldest.z
	if target_time <= oldest_time:
		return Vector2(oldest.x, oldest.y)
		
	var low: int = 0
	var high: int = history_count - 2
	
	while low <= high:
		var mid: int = (low + high) / 2
		var newer: Vector3 = get_history_item(mid)
		var older: Vector3 = get_history_item(mid + 1)
		
		var newer_time: float = newer.z
		var older_time: float = older.z
		
		if newer_time >= target_time and older_time <= target_time:
			var t: float = (target_time - older_time) / (newer_time - older_time)
			var older_pos := Vector2(older.x, older.y)
			var newer_pos := Vector2(newer.x, newer.y)
			return older_pos.lerp(newer_pos, t)
		elif newer_time < target_time:
			high = mid - 1
		else:
			low = mid + 1
			
	return Vector2(oldest.x, oldest.y)

func _draw() -> void:
	if not sprite_texture or h_frames <= 0 or marker_configs.is_empty():
		return
	
	var texture_width: float = sprite_texture.get_width()
	var texture_height: float = sprite_texture.get_height()
	
	var frame_width: float = texture_width / h_frames
	var frame_height: float = texture_height
	
	var current_time: float = accumulated_time
	var dir_sign: float = 1.0 if right_direction else -1.0
	
	if marker_frames.size() != marker_configs.size():
		_initialize_animation_arrays()
	
	for i: int in range(marker_configs.size() - 1, -1, -1):
		var config: Dictionary = marker_configs[i]
		var delay: float = config.get("delay", 0.0)
		var radius_multiplier: float = config.get("radius_multiplier", 1.0)
		var orbiter_count: int = config.get("orbiter_count", 2)
		var orbiter_period: float = config.get("orbiter_period", 32.0 / 60.0)
		var orbiter_offset: float = config.get("orbiter_offset", 0.0)
		var anim_sequences: Array = config.get("animation_indices", [])
		var alpha: float = config.get("alpha", 1.0)
		var off_frame_phase_offset: float = config.get("off_frame_phase_offset", 0.0)
		
		var modulate_color = Color(1.0, 1.0, 1.0, alpha)
		
		var target_time: float = current_time - delay
		var center_world_pos: Vector2 = get_interpolated_position(target_time)
		
		var radius: float = base_radius * radius_multiplier
		
		var current_step_idx = marker_frames[i] if i < marker_frames.size() else 0
		
		var frame_phase_shift = 0.0
		if current_step_idx % 2 != 0:
			frame_phase_shift = off_frame_phase_offset
		
		for j: int in range(orbiter_count):
			var angle: float = orbiter_offset + frame_phase_shift \
					+ dir_sign * (2.0 * PI * current_time / orbiter_period) \
					+ (2.0 * PI * j / orbiter_count)
			
			var offset_vector: Vector2 = Vector2.from_angle(angle) * radius
			var orbiter_world_pos: Vector2 = center_world_pos + offset_vector
			
			var local_pos: Vector2 = orbiter_world_pos - global_position
			
			# Sample frame index from the per-orbiter animation sequence
			var raw_frame: int = 0
			if j < anim_sequences.size() and not anim_sequences[j].is_empty():
				var seq: Array = anim_sequences[j]
				raw_frame = seq[current_step_idx % seq.size()]
			
			var marker_frame: int = posmod(raw_frame, h_frames)
			var source_rect := Rect2(marker_frame * frame_width, 0, frame_width, frame_height)
			
			var dest_rect := Rect2(
				local_pos.x - frame_width / 2.0,
				local_pos.y - frame_height / 2.0,
				frame_width,
				frame_height
			)
			
			draw_texture_rect_region(sprite_texture, dest_rect, source_rect, modulate_color)
