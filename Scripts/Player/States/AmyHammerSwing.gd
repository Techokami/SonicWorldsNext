extends PlayerState
var hammerTime = 1.0


func state_process(_delta: float) -> void:
	# handle jumping
	if parent.any_action_pressed():
		# reset animations
		parent.get_avatar().get_animator().play("RESET")
		parent.action_jump()
		parent.set_state(parent.STATES.JUMP)


func state_physics_process(delta: float) -> void:
	# if not on floor, set walk animation and return to normal or if hammer time runs out
	var animator: PlayerCharAnimationPlayer = parent.get_avatar().get_animator()
	if !parent.ground or hammerTime <= 0 or !animator.is_playing() or parent.horizontalLockTimer > 0:
		parent.set_state(parent.STATES.AIR)
		animator.play("walk")
		return
	
	# set direction
	if parent.inputs[parent.INPUTS.XINPUT] != 0:
		parent.set_direction_signed(parent.inputs[parent.INPUTS.XINPUT])
	elif parent.movement.x != 0:
		parent.set_direction_signed(signf(parent.movement.x))
	
	# set to max speed based on direction
	parent.movement.x = parent.top*parent.get_direction_multiplier()
	
	# decrease hammer time
	if hammerTime > 0:
		hammerTime -= delta
		

# enable the instashield hitmask
func state_activated():
	hammerTime = 1.0
	parent.shieldSprite.get_node("InstaShieldHitbox/HitBox").set_deferred("disabled",false)


# disable the instashield hitmask
func state_exit():
	hammerTime = 1.0
	parent.shieldSprite.get_node("InstaShieldHitbox/HitBox").set_deferred("disabled",true)
