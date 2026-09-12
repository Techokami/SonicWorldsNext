@tool
extends ConnectableGimmick

## Horizontal Swinging Bar from Mushroom Hill Zone[br]
## Author: DimensionWarped[br]
## Reworked into ConnectableGimmick by: Stanislav Gromov

## Texture used for this gimmick.[br]
## [br]
## A little info about how the texture should be arranged:[br]
## The spritesheet needs to be vertically divisible by 3. The width can be
## whatever you like, but the [code]Main_Body[/code] portion needs to stretch
## across the entirety of the bar and the texture [b]should[/b] be imported to
## repeat. If you don't repeat the texture, it will repeat the last column over
## and over instead of repeating the whole width of the body texture.[br]
## The individual parts of the texture should be vertically aligned to link up
## with one another, and delimited by 2 pixels from each other. In the included
## texture, this means the MainBody is set one pixel below the top line.
@export var sprite_texture: Texture2D = preload("res://Graphics/Gimmicks/HorizontalBar.png"):
	set(value):
		sprite_texture = value
		_resize()

## Specifies which sound to play when grabbing the bar.
@export var grab_sound: AudioStream = preload("res://Audio/SFX/Player/Grab.wav")

## How wide is this bar?
@export var width: int = 64:
	set(value):
		width = value
		_resize()

## If this is [code]false[/code], don't draw the left anchor.
## The body size will be adjusted accordingly.
@export var draw_left_anchor: bool = true:
	set(value):
		draw_left_anchor = value
		_resize()

## If this is [code]false[/code], don't draw the right anchor.
## The body size will be adjusted accordingly.
@export var draw_right_anchor: bool = true:
	set(value):
		draw_right_anchor = value
		_resize()

## How wide the left anchor is in the sprite in pixels ‒ specify this if you
## don't want the drawing to have gaps in it.
@export var left_anchor_width: int = 6:
	set(value):
		left_anchor_width = value
		_resize()

## How wide the right anchor is in the sprite in pixels ‒ specify this if you
## don't want the drawing to have gaps in it.
@export var right_anchor_width: int = 6:
	set(value):
		right_anchor_width = value
		_resize()

## If this parameter is toggled on, players may hold against
## the direction of travel to stop themselves.
@export var allow_brake: bool = false

## How many pixels per second do you want to allow the player to move side to
## side while riding ‒ affects both the shimmy and the swinging modes of the
## gimmick.
@export var shimmy_speed: float = 60.0 # one pixel per frame at 60 FPS

## Allows side to side movement on the gimmick for both shimmy mode
## and the normal bar swing.
@export var allow_shimmy: bool = true

## If this is [code]true[/code], the player may hold down when jumping
## to dismount from the gimmick downwards (only applies to shimmy mode) ‒
## otherwise the player can only jump upwards (which usually means
## re-entering the gimmick in swing mode).
@export var allow_downward_detach: bool = false

## How fast the player must be moving (upwards or downwards) when hitting the
## gimmick to enter the swing animation... usually this is rather low. If this
## value is not met when [member allow_shimmy] is on, the player will enter
## shimmy mode instead. If this value is not met and allow_shimmy is false, then
## the player will simply bypass the gimmick. In the original implementation,
## a player meets this requirement by falling for more than 32 pixels...
## or 13 frames of gravity accumulating as Y Velocity.
@export var swing_contact_speed: float = 80.0

enum _LAUNCH_SPEED_MODE { MULTIPLY, CONSTANT }
## If this is [code]MULTIPLY[/code], multiplies the speed of the incoming
## character on exit by [member multiply_swing_speed].[br]
## If this is [code]CONSTANT[/code], player always launches
## at [member swing_speed_constant].
@export var launch_speed_mode: _LAUNCH_SPEED_MODE

## When [member launch_speed_mode] is [code]CONSTANT[/code], this sets the speed at which the player will launch off with.
@export var swing_speed_constant: float = 600.0

## When [member launch_speed_mode] is [code]MULTIPLY[/code], this value sets minimum launch off speed.
@export var min_swing_speed: float = 400.0
## When [member launch_speed_mode] is [code]MULTIPLY[/code], this value sets maximum launch off speed.
@export var max_swing_speed: float = 720.0
## When [member launch_speed_mode] is [code]MULTIPLY[/code], this is the value that multiplies against the player's entry speed.
@export var multiply_swing_speed: float = 1.2

const _GIMMICK_VAR_MODE: String = "mode"
const _GIMMICK_VAR_ENTRY_VEL: String = "entry_vel"
const _GIMMICK_VAR_MOVING: String = "moving"

var _grab_sound_player: AudioStreamPlayer = null
var _half_height: float = 0.0

# TODO: Use `Dictionary[PlayerChar, bool]` when we upgrade to Godot 4.4.
var _monitored_players: Dictionary = {}

# If player enters with low absolute velocity, enter shimmy mode (unless turned off).
# If player enters from above/below with high enough velocity, enter launch mode.
enum _PLAYER_MODE { MONITORING, SHIMMY, LAUNCH }

func _add_player(player: PlayerChar) -> void:
	player.set_active_gimmick(self)
	player.set_gimmick_var(_GIMMICK_VAR_MODE, _PLAYER_MODE.MONITORING)
	player.set_gimmick_var(_GIMMICK_VAR_ENTRY_VEL, 0.0)
	player.set_gimmick_var(_GIMMICK_VAR_MOVING, false)

func _remove_player(player: PlayerChar) -> void:
	# clean up
	player.unset_gimmick_var(_GIMMICK_VAR_MOVING)
	player.unset_gimmick_var(_GIMMICK_VAR_ENTRY_VEL)
	player.unset_gimmick_var(_GIMMICK_VAR_MODE)
	player.unset_active_gimmick()

func _eject_player(player: PlayerChar, upwards: bool = false) -> void:
	var animator: PlayerCharAnimationPlayer = player.get_avatar().get_animator()
	player.set_state(player.STATES.NORMAL)
	if upwards:
		# figure out the animation based on the players current animation
		var next_animation: StringName = &"walk"
		match animator.current_animation:
			"walk", "run", "peelOut":
				next_animation = StringName(animator.current_animation)
			# if none of the animations match and speed is equal or beyond
			# the players top speed, set it to run (default is walk)
			_ when absf(player.get_ground_speed()) >= minf(6.0 * 60.0, player.get_physics().top_speed):
				next_animation = &"run"
		# play player animation
		animator.play(&"spring", -1.0, 1.0, false)
		animator.queue(next_animation)
	else:
		animator.play(&"walk", -1.0, 1.0, false)

func _clamp_player_position(player: PlayerChar) -> void:
	var half_hitbox_width: float = player.get_predefined_hitbox(PlayerChar.HITBOXES.HORIZONTAL).x * 0.5
	player.global_position.x = clampf(
		player.global_position.x,
		global_position.x + half_hitbox_width,
		global_position.x + width - half_hitbox_width)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_grab_sound_player = $Grab_Sound
	_grab_sound_player.stream = grab_sound
	_resize()

func _resize() -> void:
	# Don't do anything if the node isn't initialized yet
	if _grab_sound_player == null:
		return
	
	var main_body: Sprite2D = $Main_Body
	var left_anchor: Sprite2D = $Left_Anchor
	var right_anchor: Sprite2D = $Right_Anchor
	
	var left_anchor_actual_width: int = left_anchor_width * int(draw_left_anchor)
	var right_anchor_actual_width: int = right_anchor_width * int(draw_right_anchor)
	var main_body_width: float = float(width - left_anchor_actual_width - right_anchor_actual_width)
	var texture_height: int = sprite_texture.get_height()
	if texture_height % 3 != 0: # the 2px margin after the last sprite is optional
		texture_height += 2
	assert(texture_height % 3 == 0)
	var cell_height: float = (texture_height / 3) # including the 2px margin
	var sprite_height: float = cell_height - 2.0
	_half_height = sprite_height * 0.5
	
	left_anchor.visible = draw_left_anchor
	right_anchor.visible = draw_right_anchor
	
	main_body.position.x = float(left_anchor_actual_width)
	right_anchor.position.x = main_body.position.x + main_body_width
	
	main_body.texture = sprite_texture
	main_body.region_rect = Rect2(0.0, 0.0, main_body_width, sprite_height)
	left_anchor.texture = sprite_texture
	left_anchor.region_rect = Rect2(0.0, cell_height, float(left_anchor_width), sprite_height)
	right_anchor.texture = sprite_texture
	right_anchor.region_rect = Rect2(0.0, cell_height * 2.0, float(right_anchor_width), sprite_height)
	
	var shape: RectangleShape2D = RectangleShape2D.new()
	var shape2: RectangleShape2D = RectangleShape2D.new()
	var collision: CollisionShape2D = $Bar_Area/CollisionShape2D
	var collision2: CollisionShape2D = $Bar_Area_Outer/CollisionShape2D
	shape.size.y = 8.0
	# We don't want the player overhanging the outside of the gimmick by a lot, so clamp the size of the collision a bit.
	shape.size.x = width - 28.0
	
	shape2.size = shape.size + Vector2(8.0, 32.0)
	
	collision.set_shape(shape)
	collision2.set_shape(shape2)
	collision.position = Vector2(width * 0.5, _half_height)
	collision2.position = collision.position

func _process_player_x_movement(player: PlayerChar, x_input: float) -> bool:
	var moved_last_frame: bool = player.get_gimmick_var(_GIMMICK_VAR_MOVING)
	var moving: bool = false
	player.movement.x = 0.0
	if x_input != 0.0:
		var half_hitbox_width: float = player.get_predefined_hitbox(PlayerChar.HITBOXES.HORIZONTAL).x * 0.5
		if x_input < 0.0:
			if player.global_position.x > global_position.x + half_hitbox_width:
				player.movement.x = -shimmy_speed
				moving = true
		else: # x_input > 0.0
			if player.global_position.x < global_position.x + width - half_hitbox_width:
				player.movement.x = shimmy_speed
				moving = true
	player.set_gimmick_var(_GIMMICK_VAR_MOVING, moving)
	
	# Setting `player.movement.x` (see above) makes the player move during the
	# next frame, but they can go out of bounds (e.g. if the distance to the
	# right end of the bar is 0.25 px, but the player moves by 1.0 px).
	# To correct this, we can clamp the player's position, but only do that for
	# one frame, when the player just stopped moving, by checking variable
	# `moved_last_frame` first. Without this extra check, the clamping would
	# happen at every frame, and this would prevent horizontally moving crushers
	# from pushing the player off the bar ‒ we don't want that.
	if moved_last_frame and not moving:
		_clamp_player_position(player)
	
	# While shimmy is allowed, we are also allowed to jump off the gimmick at any time.
	if player.any_action_pressed():
		
		# If down is held and downward detach is allowed, fall down instead.
		if (allow_downward_detach and player.get_y_input() > 0.0):
			player.movement.y = 40.0
		# Otherwise the player jumps upward.
		else:
			player.movement.y = -2.0 * (player.get_physics().jump_strength / 3.0)
		
		player.set_ground_speed(0.0)
		player.set_state(player.STATES.JUMP)
		player.get_avatar().get_animator().play(&"roll")
		_remove_player(player)
		return true
	
	return false

func _process_player_shimmy_animation(player: PlayerChar) -> void:
	var animator: PlayerCharAnimationPlayer = player.get_avatar().get_animator()
	if player.get_gimmick_var(_GIMMICK_VAR_MOVING):
		animator.play()
	else:
		animator.pause()

func _process_player_launch(player: PlayerChar) -> void:
	var animator: PlayerCharAnimationPlayer = player.get_avatar().get_animator()
	var anim_pos: float = animator.get_current_animation_position() / animator.get_current_animation_length()
	var entry_vel: float = player.get_gimmick_var(_GIMMICK_VAR_ENTRY_VEL)
	
	# If brakes are allowed, we want to allow slamming the breaks
	# a little faster than the upward animation normally plays out.
	if anim_pos >= 0.91 and player.get_y_input() * entry_vel < 0.0 and allow_brake:
		player.set_gimmick_var(_GIMMICK_VAR_MODE, _PLAYER_MODE.SHIMMY)
		animator.play(&"hangShimmy", -1.0, shimmy_speed / 60.0, false)
	
	# Otherwise we just launch the player on out of the gimmick.
	# DW's note ‒ this multiplication stuff with the length was stupid of me
	# and I really should have been relying on signals.
	if anim_pos >= 0.97:
		_eject_player(player, entry_vel < 0.0)
		
		player.movement.y = (
				swing_speed_constant if launch_speed_mode == _LAUNCH_SPEED_MODE.CONSTANT else
				clampf(absf(entry_vel) * multiply_swing_speed, min_swing_speed, max_swing_speed)
			) * signf(entry_vel)
		_remove_player(player)

func _process_player_monitoring(player: PlayerChar) -> void:
	var animator: PlayerCharAnimationPlayer = player.get_avatar().get_animator()
	if absf(player.movement.y) >= swing_contact_speed:
		# This is ok for now, but we need to clean it up.
		animator.play(&"swingHorizontalBarMHZ", -1.0, 1.0, false)
		player.set_gimmick_var(_GIMMICK_VAR_MODE, _PLAYER_MODE.LAUNCH)
		player.set_gimmick_var(_GIMMICK_VAR_ENTRY_VEL, player.movement.y)
	
	else:
		animator.play(&"hangShimmy", -1.0, shimmy_speed / 60.0, false)
		player.set_gimmick_var(_GIMMICK_VAR_MODE, _PLAYER_MODE.SHIMMY)
	
	player.sprite.flip_h = false
	player.movement.y = 0.0
	player.global_position.y = global_position.y + _half_height
	player.set_state(player.STATES.GIMMICK)
	_grab_sound_player.play()

func player_physics_process(player: PlayerChar, _delta: float) -> void:
	var x_input: float = player.get_x_input()
	
	# If the player is in monitoring mode, we check for when to stick them to the bar
	if player.get_gimmick_var(_GIMMICK_VAR_MODE) == _PLAYER_MODE.MONITORING:
		_process_player_monitoring(player)
	
	# Eject the player if something like a platform picks them up from below,
	# or if something pushes them from above.
	if player.ground or player.check_for_ceiling():
		player.global_position.y = global_position.y + player.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL).y
		_eject_player(player)
		_remove_player(player)
		return
	
	# As long as shimmying is allowed, shimmying is allowed in all active modes.
	if allow_shimmy and _process_player_x_movement(player, x_input):
		return
	
	# Always lock y movement while in any of the modes.
	# Always reset position in case this thing is moving for some reason.
	player.movement.y = 0.0
	player.global_position.y = global_position.y + _half_height
	
	match player.get_gimmick_var(_GIMMICK_VAR_MODE):
		_PLAYER_MODE.SHIMMY:
			_process_player_shimmy_animation(player)
		_PLAYER_MODE.LAUNCH:
			_process_player_launch(player)

func player_force_detach_callback(player: PlayerChar) -> void:
	_remove_player(player)

func _on_bar_area_body_entered(player: PlayerChar) -> void:
	if player in _monitored_players and not player.ground:
		_add_player(player)
		_clamp_player_position(player)
		
		# Prevent the player from re-entering the gimmick
		# until they leave and re-enter the outer Area2D first.
		_monitored_players.erase(player)

func _on_bar_outer_area_body_entered(player: PlayerChar) -> void:
	_monitored_players[player] = true

func _on_bar_outer_area_body_exited(player: PlayerChar) -> void:
	_monitored_players.erase(player)
	
	# Remove the player if something like a moving crusher pushes them out.
	if player.get_active_gimmick() == self:
		player.global_position.y = global_position.y + 26.0
		_eject_player(player)
		_remove_player(player)
