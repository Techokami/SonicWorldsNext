## Character specific Avatar for Amy Rose
class_name AmyAvatar extends PlayerAvatar


## Order of CHAR_STATES should be the same as the order of nodes under CharacterStates in
## AmyAvatar's scene file.
enum CHAR_STATES {
	AMY_HAMMER_SWING,
}

func get_hitbox(hitbox_type: PlayerChar.HITBOXES):
	return hitboxes[hitbox_type]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	normal_sprite = preload("res://Graphics/Players/Amy.png")
	super_sprite = null
	
	hitboxes = [
		Vector2(9,15)*2,  # NORMAL
		Vector2(7,11)*2,  # ROLL
		Vector2(9,9.5)*2, # CROUCH
		Vector2(10,10)*2, # GLIDE
		Vector2(16,11)*2  # HORIZONTAL
	]


# Amy's double jump action (Spinning hammer jump)
func amy_jump_hammer_callback(_state: PlayerState, player: PlayerChar, _delta: float):
	if player.abilityUsed:
		return true
	
	if !player.any_action_pressed():
		return true
	
	# Amy's hammer can only be moved if she's rising slower than the jump release speed
	if player.movement.y < -player.get_physics().release_jump * 60:
		return true
	
	# set ability used to true to prevent multiple uses
	player.abilityUsed = true
	# enable insta shield hitbox if hammer drop dashing
	player.shieldSprite.get_node("InstaShieldHitbox/HitBox").disabled = (
		get_animator().current_animation == "dropDash"
	)
	# play hammer sound
	player.sfx[30].play()
	# play dropDash sound
	get_animator().play("dropDash")
	pass


# drop dash variables
const DROP_SPEED = [8,12] #the base speed for a drop dash, second is super
const DROP_MAX = [12,13]   #the top speed for a drop dash, second is super
var drop_timer = 0


# Amy's jump and hold move (drop dash)
func amy_jump_dropdash_callback(_state: PlayerState, player: PlayerChar, delta: float):
	
	if !(player.any_action_held_or_pressed() and player.abilityUsed):
		drop_timer = 0
		
		# If the player released drop dash, it's time to put the jump back to normal
		if get_animator().current_animation == "dropDash":
			get_animator().play("roll")
		
		# The rest of this function is for charging the jumpdash.
		return true
		
	if drop_timer < 1:
		drop_timer += (delta/20)*60 # should be ready in the equivelent of 20 frames at 60FPS
		if drop_timer >= 1:
			player.sfx[20].play()
		else:
			if get_animator().current_animation != "dropDash":
				get_animator().play("dropDash")
	pass
	
	return true


# What happens when Amy lands from dropdash prep.
func amy_exit_jump_dropdash_callback(_exit_state: PlayerState,
		enter_state: PlayerChar.STATES,
		player: PlayerChar,
		_enter_character_state: int = -1
):
	
	# Need to disable instashield hitbox on state exit regardless of other factors
	player.shieldSprite.get_node("InstaShieldHitbox/HitBox").disabled = true

	# If we haven't been charging the drop dash long enough, we bail here.
	if drop_timer <= 1:
		drop_timer = 0
		return true
	
	# we reset the drop timer regardless of the previous condition since we're changing states.
	drop_timer = 0
	
	# If the state is neither of the standard landing states, we bail here.
	if enter_state != PlayerChar.STATES.NORMAL and enter_state != PlayerChar.STATES.ROLL:
		return true
	
	# Check if moving forward or back
	# Forward landing
	var is_super := int(player.isSuper)
	var direction := player.get_direction_multiplier()
	var drop_speed: int = DROP_SPEED[is_super] * 60
	var drop_max: int = DROP_MAX[is_super] * 60

	# Forward Landing
	if sign(player.movement.x) == direction or player.movement.x == 0:
		player.movement.x = clamp(
			(player.movement.x / 4.0) + (drop_speed * direction),
			-drop_max,
			drop_max
		)
	# Backwards landing
	else:
		# if floor angle is flat then just set to drop speed
		if is_equal_approx(player.get_angle(), player.gravityAngle):
			player.movement.x = drop_speed * direction
		# else calculate landing
		else:
			player.movement.x = clamp(
				(player.movement.x / 2.0) + (drop_speed * direction),
				-drop_max,
				drop_max
			)
	
	player.movement.y = min(0,player.movement.y)
	player.set_character_action_state(CHAR_STATES.AMY_HAMMER_SWING, Vector2.ZERO, true)
	get_animator().play("hammerSwing")
	player.sfx[20].stop()
	player.sfx[3].play()
	
	# Don't allow the regular transition to continue! We want the player to stay in roll!
	return false


func register_state_modifications(player: PlayerChar):
	var jump_state = player.get_state_object(PlayerChar.STATES.JUMP)
	jump_state.register_process_supplement(amy_jump_hammer_callback)
	jump_state.register_process_supplement(amy_jump_dropdash_callback)
	jump_state.register_exit_supplement(amy_exit_jump_dropdash_callback)


## Amy can break things casually if she is using her hammer.
func get_break_power(player: PlayerChar) -> int:
	## Coming after I move character-specific states.
	
	return super(player)
