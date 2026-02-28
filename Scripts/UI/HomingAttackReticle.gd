@tool

class_name HomingAttackReticle extends Node2D

@export var rotation_speed := PI / 3

@export var current_target : Targetable = null
@export var old_target : Targetable = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ReticleAnimator.play(&"none")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var reticleD: ReticleDrawerHuman = $ReticleDrawer
	reticleD.reticle_rotation += delta * rotation_speed
	if reticleD.reticle_rotation > 2 * PI:
		reticleD.reticle_rotation -= 2 * PI
	
	# When swapping targets, we need to lerp between the old target and current target positions.
	if current_target != null and old_target != null:
		var anim_position = clamp(2 * $ReticleAnimator.current_animation_position / $ReticleAnimator.current_animation_length, 0.0, 1.0)
		global_position = old_target.global_position.lerp(current_target.global_position, anim_position)
		if (anim_position) == 1.0:
			old_target = null

	elif current_target != null:
		# Update position to the current target every time
		global_position = current_target.global_position

func set_target(new_target: Targetable) -> void:
	var fresh = true
	
	#print("current_target %s" % current_target)
	#print("new_target %s" % new_target)

	if current_target != null:
		old_target = current_target
		fresh = false
	
	current_target = new_target
	
	if new_target == null:
		#print("mode 1")
		$ReticleAnimator.play(&"RESET")
		$ReticleAnimator.play(&"clear_target")
		return
	
	if fresh:
		#print("mode 2")
		$ReticleAnimator.play(&"RESET")
		$ReticleAnimator.play(&"fresh_target")
	else:
		#print("mode 3")
		$ReticleAnimator.play(&"RESET")
		$ReticleAnimator.play(&"swap_target")
