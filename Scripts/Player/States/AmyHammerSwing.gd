extends PlayerState
var hammerTime = 1.0


func _physics_process(delta):
	# if not on floor, set walk animation and return to normal or if hammer time runs out
	if !parent.ground or hammerTime <= 0 or !parent.animator.is_playing() or parent.horizontalLockTimer > 0:
		parent.set_state(parent.STATES.AIR)
		parent.animator.play("walk")
		# return null to cancel script
		return null
	
	# set direction
	if parent.inputs[parent.INPUTS.XINPUT] != 0:
		parent.direction = parent.inputs[parent.INPUTS.XINPUT]
	elif parent.movement.x != 0:
		parent.direction = sign(parent.movement.x)
	
	# set to max speed based on direction
	parent.movement.x = parent.top*parent.direction
	
	# flip sprite based on direction
	parent.sprite.flip_h = (parent.direction < 0)
	
	# decrease hammer time
	if hammerTime > 0:
		hammerTime -= delta
	
	

func _process(_delta):
	# handle jumping
	if parent.any_action_pressed():
		# reset animations
		parent.animator.play("RESET")
		parent.action_jump()
		parent.set_state(parent.STATES.JUMP)

# enable the instashield hitmask
func state_activated():
	hammerTime = 1.0
	parent.shieldSprite.get_node("InstaShieldHitbox/HitBox").set_deferred("disabled",false)

# disable the instashield hitmask
func state_exit():
	hammerTime = 1.0
	parent.shieldSprite.get_node("InstaShieldHitbox/HitBox").set_deferred("disabled",true)
