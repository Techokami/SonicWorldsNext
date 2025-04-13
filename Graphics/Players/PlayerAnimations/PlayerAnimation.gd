## Extends the animation player so that we can track some additional things
## about the animation of the player that wouldn't be provided by the standard
## animation player
class_name PlayerCharAnimationPlayer extends AnimationPlayer

# Note that looping animations need to explicitly increment cur_loops in order
# for this to work! Otherwise loops won't be counted.
@export var cur_loops: int = 0

## Should be invoked instead of play whenever possible
## Works the same as regular play(), but resets loop count on entry.
## Would have liked to override the base play and use super to invoke the
## AnimationPlayer function instead, but Godot won't let me.
func play_proxy(animation_name: StringName = &"", custom_blend: float = -1,
				custom_speed: float = 1.0, from_end: bool = false):
	cur_loops = 0
	play(animation_name, custom_blend, custom_speed, from_end)
	
## Resets the loop count. Might be useful if you are controlling the animator
## directly.
func reset_loops() -> void:
	cur_loops = 0

## Increments the loop count by 1 -- meant for use by the
## PlayerCharAnimationPlayer
func increment_loops() -> void:
	cur_loops += 1
	
func get_loops() -> int:
	return cur_loops
