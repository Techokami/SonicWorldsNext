## The PlayerAvatar class contains the specific attributes of your character.
## For now this just contains the specific attributes and collision boxes for the character,
## but with future refactoring this could include things like input mappings and per state
## character code.
extends PlayerAvatar

# Used for electric shield double-jump ability
var elecPart = preload("res://Entities/Misc/ElecParticles.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	normal_sprite = preload("res://Graphics/Players/Sonic.png")
	super_sprite = preload("res://Graphics/Players/SuperSonic.png")
	
	hitboxes = [
		Vector2(9,19)*2,  # NORMAL
		Vector2(7,14)*2,  # ROLL
		Vector2(9,11)*2,  # CROUCH
		Vector2(10,10)*2, # GLIDE
		Vector2(16,14)*2  # HORIZONTAL
	]


# All attributes for this base class are used by Sonic
func get_hitbox(hitbox_type: PlayerChar.HITBOXES):
	return hitboxes[hitbox_type]


func activate_instashield(_state: PlayerState, player: PlayerChar):
	var clear_shield_cb = func ():
		if player.get_shield() == PlayerChar.SHIELDS.NONE:
			player.shieldSprite.visible = false
			player.shieldSprite.stop()
			# disable insta shield
			var hitbox = player.shieldSprite.get_node("InstaShieldHitbox/HitBox")

			if hitbox != null:
				hitbox.disabled = true
	
	player.abilityUsed = true
	player.sfx[16].play()
	player.shieldSprite.play("Insta")
	player.shieldSprite.frame = 0
	player.shieldSprite.visible = true
	# enable insta shield hitbox
	player.shieldSprite.get_node("InstaShieldHitbox/HitBox").disabled = false
	player.shieldSprite.animation_finished.connect(clear_shield_cb)

	return true


# Electric shield double-jump ability
func activate_elecshield(_state: PlayerState, player: PlayerChar):
	player.abilityUsed = true
	player.sfx[13].play()
	# set movement upwards
	player.movement.y = -5.5*60.0
	# generate 4 electric particles and send them out diagonally (rotated for each iteration of i to 4)
	for i in range(4):
		var part = elecPart.instantiate()
		part.global_position = player.global_position
		part.direction = Vector2(1,1).rotated(deg_to_rad(90*i))
		player.get_parent().add_child(part)
	
	return true


# Flame Shield double-jump ability
func activate_fireshield(_state: PlayerState, player: PlayerChar):
	# partner check (so you don't flame boost when you're trying to fly with tails
	if player.get_y_input() < 0 and player.partner != null:
		return true
	
	player.abilityUsed = true
	
	player.sfx[14].play()
	player.movement = Vector2(8*60*player.get_direction_multiplier(),0)
	player.shieldSprite.play("FireAction")
	
	# set timer for animation related resets
	var getTimer = player.shieldSprite.get_node_or_null("ShieldTimer")
	# Start fire dash timer
	if getTimer != null:
		getTimer.start(0.5)
		
	# change orientation to match the movement
	player.shieldSprite.flip_h = (player.get_direction() != PlayerChar.DIRECTIONS.RIGHT)
		# lock camera for a short time
	player.lock_camera(16.0/60.0)


# Bubble Shield double-jump ability
func activate_bubbleshield(_state: PlayerState, player: PlayerChar):
	# check animation isn't already bouncing
	if player.shieldSprite.animation != "BubbleBounce":
		player.sfx[15].play()
		# set movement and bounce reaction
		player.movement = Vector2(0,8*60)
		if player.is_in_water():
			player.bounceReaction = 4.0
		else:
			player.bounceReaction = 7.5
		player.shieldSprite.play("BubbleAction")
		# set timer for animation related resets
		var getTimer = player.shieldSprite.get_node_or_null("ShieldTimer")
		# Start bubble timer
		if getTimer != null:
			getTimer.start(0.25)
		else:
			player.abilityUsed = false


# Sonic's double-jump moves (shields)
func sonic_jump_shields_callback(state: PlayerState, player: PlayerChar, _delta: float):
	# If the player is currently invincible due to invincibility monitor or Super form,
	# don't use any shield moves. We might add in improvement to enable instashield later.
	if player.supTime > 0:
		if player.any_action_pressed():
			player.abilityUsed = true
		return true

	# Shields can only be activated while the player is moving slower than the jump release speed.
	if player.movement.y < -player.get_physics().release_jump * 60:
		return true
		
	if player.any_action_pressed() and !player.abilityUsed:
		# Shield actions
		match (player.get_shield()):
			PlayerChar.SHIELDS.NONE:
				return activate_instashield(state, player)
			PlayerChar.SHIELDS.ELEC:
				return activate_elecshield(state, player)
			PlayerChar.SHIELDS.FIRE:
				return activate_fireshield(state, player)
			PlayerChar.SHIELDS.BUBBLE:
				return activate_bubbleshield(state, player)
	
	return true
	
	
# drop dash variables
const DROP_SPEED = [8,12] #the base speed for a drop dash, second is super
const DROP_MAX = [12,13]   #the top speed for a drop dash, second is super
var drop_timer = 0


# Sonic's jump and hold move (drop dash)
func sonic_jump_dropdash_callback(_state: PlayerState, player: PlayerChar, delta: float):
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


func sonic_exit_jump_dropdash_callback(_exit_state: PlayerState,
		enter_state: PlayerChar.STATES,
		player: PlayerChar,
		_enter_character_state: int = -1):
	
	# TODO - Optional Sonic Mania spike parry by making this based on Improvements Flag
	#parent.shieldSprite.get_node("InstaShieldHitbox/HitBox").set_deferred("disabled",true)
	# NOTE: We want to put this in a separate exit callback just for shields
	
	# If the state is neither of the standard landing states, we bail here.
	if enter_state != PlayerChar.STATES.NORMAL and enter_state != PlayerChar.STATES.ROLL:
		return true

	# If we haven't been charging the drop dash long enough, we bail here.
	if drop_timer <= 1:
		drop_timer = 0
		return true
	
	# we reset the drop timer regardless of the previous condition since we're changing states.
	drop_timer = 0
	
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
	
	# Stop the vertical component of movement. Drop dash doesn't benefit from slope entry.
	player.movement.y = min(0,player.movement.y)
	# Need to use a version of set_state that skips supplements or else we will lock up from a recursive shitstorm.
	player.set_state(PlayerChar.STATES.ROLL, Vector2.ZERO, true)
	get_animator().play("roll")
	# TODO - Move these sound effect into the PlayerAvatar object for Sonic.
	player.sfx[20].stop()
	player.sfx[3].play()

	# Lag camera
	player.lock_camera(16.0/60.0)
	
	# drop dash dust
	var dust = player.Particle.instantiate()
	dust.play("DropDash")
	dust.global_position = player.global_position+Vector2(0,2).rotated(player.rotation)
	dust.scale.x = player.get_direction_multiplier()
	player.get_parent().add_child(dust)
	
	# Don't allow the regular transition to continue! We want the player to stay in roll!
	return false


func sonic_normal_peelout_callback(_state: PlayerState, player: PlayerChar, _delta: float):
	# Player is moving, we can't go into peelout
	if player.movement.x != 0:
		return true

	# Player is not holding up and pressing a button, we won't go into peelout
	if player.get_y_input() >= 0 or !player.any_action_held_or_pressed():
		return true
	
	player.sfx[2].play()
	player.sfx[2].pitch_scale = 1
	player.spindashPower = 0
	player.set_state(PlayerChar.STATES.PEELOUT, Vector2.ZERO, true)
	
	return false


func bubbleshield_handle_bounce(player: PlayerChar):
	# bubble shield actions
	var shieldAnimation = player.shieldSprite.animation
	if shieldAnimation != "BubbleAction" and shieldAnimation != "Bubble":
		return
	
	player.shieldSprite.play("BubbleBounce")
	player.sfx[15].play()
	var getTimer = player.shieldSprite.get_node_or_null("ShieldTimer")
	# Start bubble timer
	if getTimer != null:
		getTimer.start(0.15)


## Sonic needs the following modifications to states --
## 1 - Super Peel Out added to Ground State
## 2 - Insta-shield / Elemental Shield actions added to Air State
## 3 - Drop Dash added to the transition from Air to Ground state
func register_state_modifications(player: PlayerChar):
	var jump_state = player.get_state_object(PlayerChar.STATES.JUMP)
	var normal_state = player.get_state_object(PlayerChar.STATES.NORMAL)
	jump_state.register_process_supplement(sonic_jump_shields_callback)
	player.player_bounced.connect(bubbleshield_handle_bounce)
	jump_state.register_process_supplement(sonic_jump_dropdash_callback)
	jump_state.register_exit_supplement(sonic_exit_jump_dropdash_callback)
	normal_state.register_process_supplement(sonic_normal_peelout_callback)


## Sonic has a few special break conditions that differentiate him from the others.
func get_break_power(player: PlayerChar) -> int:
	# Super Sonic always breaks normal blocks, but not Knuckles only blocks.
	if player.isSuper:
		return 2
	
	# The fire shield's dash can also break strength 2 blocks.
	if (player.shieldSprite.animation == "FireAction" and
			player.get_state() == PlayerChar.STATES.JUMP):
		return 2
	
	return super(player)
