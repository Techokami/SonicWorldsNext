@tool

## Controls the rotating star pattern that follows the player when they get an invincibility
## monitor

extends Node2D

## The spritesheet texture containing the animation frames.
@export var sprite_texture: Texture2D = preload("res://Graphics/Items/invincible_stars_s2.png"):
	set(val):
		sprite_texture = val
		queue_redraw()

## Total number of horizontal frames in the sprite sheet texture.
@export var h_frames: int = 9

## Duration of each individual animation frame in seconds (defaults to 1/60th of a second).
@export var frame_duration: float = 1.0 / 60.0

## If true, the animation bounces back and forth between min_frame and max_frame. 
## If false, it loops.
@export var ping_pong: bool = true

## Enables standalone scene testing (F6) with automatic camera creation and mouse tracking.
@export var test_mode: bool = false

## Standard base radius distance at which orbiters rotate around their 
## tracked position history points.
@export var base_radius: float = 17.0

## Global rotation direction for orbiters (true for clockwise, false for counter-clockwise). 
## Automatically updated by horizontal mouse movement when test_mode is active.
@export var right_direction: bool = true

## Array of configuration dictionaries defining each trail/marker level (delay, 
## sprite frame offsets, radius multipliers, orbiter counts, periods, phase offsets, 
## min/max frames, and alpha).
@export var marker_configs: Array[Dictionary] = [
	{ 
		"delay": 0.0, 
		"sprite_delay": 0, 
		"radius_multiplier": 1.0, 
		"orbiter_count": 2, 
		"orbiter_period": 32.0 / 60.0, 
		"orbiter_offset": 0.0,
		"min_frame": 2,
		"max_frame": 9,
		"alpha": 1.0,
		"off_frame_phase_offset": PI / 2.0
	},
	{ 
		"delay": (3.0 / 60.0), 
		"sprite_delay": 2, 
		"radius_multiplier": 1.0, 
		"orbiter_count": 2, 
		"orbiter_period": 32.0 / 60.0, 
		"orbiter_offset": PI / 4.0,
		"min_frame": 2,
		"max_frame": 9,
		"alpha": 1.0,
		"off_frame_phase_offset": 0.0
	},
	{ 
		"delay": (6.0 / 60.0), 
		"sprite_delay": 2 * 2, 
		"radius_multiplier": 1.0, 
		"orbiter_count": 2, 
		"orbiter_period": 32.0 / 60.0, 
		"orbiter_offset": 2.0 * PI / 4.0,
		"min_frame": 1,
		"max_frame": 8,
		"alpha": 1.0,
		"off_frame_phase_offset": 0.0
	},
	{ 
		"delay": (9.0 / 60.0), 
		"sprite_delay": 2 * 3, 
		"radius_multiplier": 1.0, 
		"orbiter_count": 2, 
		"orbiter_period": 32.0 / 60.0, 
		"orbiter_offset": 3.0 * PI / 4.0,
		"min_frame": 0,
		"max_frame": 8,
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
					"sprite_delay": 0, 
					"radius_multiplier": 1.0, 
					"orbiter_count": 2, 
					"orbiter_period": 32.0 / 60.0, 
					"orbiter_offset": 0.0,
					"min_frame": 0,
					"max_frame": h_frames,
					"alpha": 1.0,
					"off_frame_phase_offset": 0.0
				}
			
			for i in range(marker_configs.size(), val.size()):
				if val[i].is_empty():
					val[i] = template.duplicate(true)
					
		marker_configs = val
		if Engine.is_editor_hint():
			_initialize_animation_arrays()

# Used to adjust the default draw pos when running in test mode
var custom_draw_pos: Vector2 = Vector2.ZERO
# Used to track direction when running in test mode
var last_mouse_pos: Vector2 = Vector2.ZERO

# Tracks the current animation frame of each circle's effects
var marker_frames: Array = []
# Tracks whether the direction is going up in number or down for ping-pong mode
var marker_directions: Array = []
# Used to mark time accumulated within the marker (needed because each marker can
# set its own period)
var marker_time_accumulators: Array = []

# Pre-allocated Circular Ring Buffer variables for O(1) writes, O(Log(n)) reads
# Note that this might be error prone if the tail ever starts to read further pack than
# we can reliably write. Consider constraining the writes to a n per second in the future.
const HISTORY_SIZE: int = 300
var position_history: Array = []
var write_index: int = 0
var history_count: int = 0

func _ready() -> void:
	if not Engine.is_editor_hint() and get_tree().current_scene == self:
		test_mode = true
		
		var camera = Camera2D.new()
		camera.position = Vector2(0, 0)
		camera.enabled = true
		add_child(camera)
		
	_initialize_animation_arrays()
		
	position_history.resize(HISTORY_SIZE)
	for i in range(HISTORY_SIZE):
		position_history[i] = { "pos": Vector2.ZERO, "time": 0.0 }
		
	last_mouse_pos = get_local_mouse_position()
	
	top_level = true

func _initialize_animation_arrays() -> void:
	marker_frames.clear()
	marker_directions.clear()
	marker_time_accumulators.clear()
	
	for config in marker_configs:
		var min_f = config.get("min_frame", 0)
		marker_frames.append(min_f)
		marker_directions.append(1)
		marker_time_accumulators.append(0.0)

func _process(delta: float) -> void:
	
	if Engine.is_editor_hint():
		queue_redraw()
		return
	elif !test_mode:
		# Because the InvincibilityBarrier is a top_level node, we need to manually reposition it.
		self.global_position = get_parent().global_position
		
	if test_mode:
		# When running as a standalone scene, we want the mouse to control the positioning of
		# the barrier's root position.
		var current_mouse_pos = get_local_mouse_position()
		if current_mouse_pos.x > last_mouse_pos.x:
			right_direction = true
		elif current_mouse_pos.x < last_mouse_pos.x:
			right_direction = false
		last_mouse_pos = current_mouse_pos
		custom_draw_pos = current_mouse_pos
	else:
		custom_draw_pos = Vector2.ZERO
	
	record_position_history()
	
	if not sprite_texture or marker_configs.is_empty():
		return
	
	if marker_frames.size() != marker_configs.size():
		_initialize_animation_arrays()
	
	for i in range(marker_configs.size()):
		var config = marker_configs[i]
		var min_frame = config.get("min_frame", 0)
		var max_frame = config.get("max_frame", h_frames)
		
		if max_frame <= min_frame:
			continue
			
		marker_time_accumulators[i] += delta
		if marker_time_accumulators[i] >= frame_duration:
			marker_time_accumulators[i] = 0.0
			
			marker_frames[i] += marker_directions[i]
			
			if marker_frames[i] >= max_frame:
				if ping_pong:
					marker_directions[i] = -1
					marker_frames[i] = max_frame - 2
				else:
					marker_frames[i] = min_frame
			elif marker_frames[i] < min_frame:
				if ping_pong:
					marker_directions[i] = 1
					marker_frames[i] = min_frame + 1
				else:
					marker_frames[i] = max_frame - 1
					
	queue_redraw()

func record_position_history() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var effective_world_pos = global_position + custom_draw_pos
	
	position_history[write_index] = { "pos": effective_world_pos, "time": current_time }
	write_index = (write_index + 1) % HISTORY_SIZE
	
	if history_count < HISTORY_SIZE:
		history_count += 1

func get_history_item(i: int) -> Dictionary:
	var physical_index = (write_index - 1 - i + HISTORY_SIZE) % HISTORY_SIZE
	return position_history[physical_index]

func get_interpolated_position(target_time: float) -> Vector2:
	if history_count == 0:
		return global_position + custom_draw_pos
		
	var newest = get_history_item(0)
	if target_time >= newest.time:
		return newest.pos
		
	var oldest = get_history_item(history_count - 1)
	if target_time <= oldest.time:
		return oldest.pos
		
	var low = 0
	var high = history_count - 2
	
	while low <= high:
		var mid = (low + high) / 2
		var newer = get_history_item(mid)
		var older = get_history_item(mid + 1)
		
		if newer.time >= target_time and older.time <= target_time:
			var t = (target_time - older.time) / (newer.time - older.time)
			return older.pos.lerp(newer.pos, t)
		elif newer.time < target_time:
			high = mid - 1
		else:
			low = mid + 1
			
	return oldest.pos

func _draw() -> void:
	if not sprite_texture or h_frames <= 0 or marker_configs.is_empty():
		return
	
	var texture_width = sprite_texture.get_width()
	var texture_height = sprite_texture.get_height()
	
	var frame_width = texture_width / h_frames
	var frame_height = texture_height
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var dir_sign: float = 1.0 if right_direction else -1.0
	
	if marker_frames.size() != marker_configs.size():
		_initialize_animation_arrays()
	
	for i in range(marker_configs.size() - 1, -1, -1):
		var config = marker_configs[i]
		var delay = config.get("delay", 0.0)
		var sprite_delay = config.get("sprite_delay", 0)
		var radius_multiplier = config.get("radius_multiplier", 1.0)
		var orbiter_count = config.get("orbiter_count", 2)
		var orbiter_period = config.get("orbiter_period", 32.0 / 60.0)
		var orbiter_offset = config.get("orbiter_offset", 0.0)
		var max_frame = config.get("max_frame", h_frames)
		var alpha = config.get("alpha", 1.0)
		var off_frame_phase_offset = config.get("off_frame_phase_offset", 0.0)
		
		var modulate_color = Color(1.0, 1.0, 1.0, alpha)
		
		var target_time = current_time - delay
		var center_world_pos = get_interpolated_position(target_time)
		
		var radius = base_radius * radius_multiplier
		
		var current_level_frame = marker_frames[i] if i < marker_frames.size() else 0
		
		var frame_phase_shift = 0.0
		if current_level_frame % 2 != 0:
			frame_phase_shift = off_frame_phase_offset
		
		for j in range(orbiter_count):
			var angle = orbiter_offset + frame_phase_shift \
					+ dir_sign * (2.0 * PI * current_time / orbiter_period) \
					+ (2.0 * PI * j / orbiter_count)
			
			var offset_vector = Vector2(cos(angle), sin(angle)) * radius
			var orbiter_world_pos = center_world_pos + offset_vector
			
			var local_pos = orbiter_world_pos - global_position
			
			var marker_frame = posmod(current_level_frame - sprite_delay, max_frame)
			var source_rect = Rect2(marker_frame * frame_width, 0, frame_width, frame_height)
			
			var dest_rect = Rect2(
				local_pos.x - frame_width / 2.0,
				local_pos.y - frame_height / 2.0,
				frame_width,
				frame_height
			)
			
			draw_texture_rect_region(sprite_texture, dest_rect, source_rect, modulate_color)
