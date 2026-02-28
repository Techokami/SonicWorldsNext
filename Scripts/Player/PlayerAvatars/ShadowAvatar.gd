## The PlayerAvatar class contains the specific attributes of your character.
## For now this just contains the specific attributes and collision boxes for the character,
## but with future refactoring this could include things like input mappings and per state
## character code.
class_name ShadowAvatar extends PlayerAvatar

# homing attack is available while airborn -- reset when landing, switching to climb, or bouncing
# off of something
var homing_attack_available := true

# stomp attack is available while airborn -- reset when landing, switching to climb, or bouncing
# off of something
var stomp_available := true

# The wall cling has been engaged -- set to true when jump dash is used. Stays true until you
# hit the ground or bounce off of something
var cling_enabled := false

## The player can cancel homing attack/jump dash with stomp
@export var stomp_cancel := true
## The player can cencel stomp with homing attack/jump dash
@export var homing_attack_cancel := true
## How long Shadow is locked out of abilities after bouncing on something (in seconds)
@export var bounce_lock_time := 0.1


# The current target selected
var current_target: Targetable = null

var controller_direction: Vector2 = Vector2(1.0, 0.0)
# Time passed since the target was last considered the best candidate. Once this time rises
# above the target_sticky_time, the target will be changed to whatever the new best target is.
var homing_attack_target_decay := 0.0

enum CHAR_STATES {
	SHADOW_STOMP,
	SHADOW_HOMING_ATTACK,
	SHADOW_WALL_CLING,
}

# Prevents Shadow from using abilities too soon after a bounce
var ability_lock_timer := 0.0

@onready var sfx = $SFX.get_children()
@onready var vfx_animator: AnimationPlayer = $Sprite2D/VFXAnimator
@onready var homing_tracker: TargetTracker = $HomingAttackArea
@onready var homing_reticle: HomingAttackReticle = $HomingAttackReticle
@onready var parent: PlayerChar = get_parent()
@onready var homing_attack_state: HomingAttackState = $CharacterStates/ShadowHomingAttack
@onready var stomp_state: PlayerState = $CharacterStates/ShadowStomp

var homing_attack_cur_target: Node2D = null

var burst = preload("uid://qoi31pj80g6r") #ShadowExtras/ShadowBurst.tscn

# All attributes for this base class are used by Shadow
func get_hitbox(hitbox_type: PlayerChar.HITBOXES):
	return hitboxes[hitbox_type]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	normal_sprite = preload("res://Graphics/Players/Shadow.png")
	super_sprite = null
	
	hitboxes = [
		Vector2(9,19)*2,  # NORMAL
		Vector2(7,14)*2,  # ROLL
		Vector2(9,11)*2,  # CROUCH
		Vector2(10,10)*2, # GLIDE
		Vector2(16,14)*2  # HORIZONTAL
	]

func _process(delta: float) -> void:
	# Copy orientational properties of the player srite to the flame sprite
	$Sprite2D/Flames.flip_h = $Sprite2D.flip_h
	$Sprite2D/Flames.flip_v = $Sprite2D.flip_v
	
	ability_lock_timer -= delta
	
	# Used to control the orientation of the collision box
	controller_direction = Vector2(parent.get_x_input(), parent.get_y_input())
	
	# Used for determining best angle only, does not impact collision box orientation
	var preferred_angle = controller_direction
	
	# If the player is holding in an upward direction, this does not control
	if controller_direction.y < 0:
		controller_direction.y = 0
	
	# Allow the player to adjust the collision box direction
	# XXX Consider moving homing attack field stuff to jump process
	homing_tracker.set_rotation(0)
	if parent.get_direction() == PlayerChar.DIRECTIONS.RIGHT:
		homing_tracker.scale.x = 1.0
		if controller_direction.length() > 0:
			homing_tracker.set_rotation(controller_direction.angle())
	else:
		homing_tracker.scale.x = -1.0
		if controller_direction.length() > 0:
			homing_tracker.set_rotation(controller_direction.angle() + PI)
			
	# If grounded, go ahead and set the current target for the homing attack tracker off
	if parent.is_on_ground() and homing_reticle.current_target != null:
		homing_reticle.set_target(null)
	
func _on_player_animation_animation_started(anim_name: StringName) -> void:
	var flame_anim: String = $FlameAnimator.current_animation

	# If we aren't running/peeling out, go ahead and reset the flame animator
	if anim_name != "run" and anim_name != "peelOut":
		$FlameAnimator.play("RESET")
		return
	
	# If the flame animator is already playing one of the enable animations, don't change it.
	if flame_anim == "enabled" or flame_anim == "enable_slow":
		return

	# Set the flame animator based on the player animator's animation. Run gets the slow startup,
	# peelout gets the fast start.
	if anim_name == "run":
		$FlameAnimator.play("enable_slow")
		return
	
	if anim_name == "peelOut":
		$FlameAnimator.play("enabled")
		
func _on_flame_animator_animation_finished(anim_name: StringName) -> void:
	if anim_name == "enable_slow":
		$FlameAnimator.play("enabled")


## Shadow can break things if he is actively boosting or using power stomp.
func get_break_power(player: PlayerChar) -> int:
	## Coming after Shadow actually has moves
	return super(player)
	
## NOTE: Controller mapping rework planned in the future to include per-character action mappings
#region controller_functions
## Jumping is either A or C on Genesis layout
func shadow_any_jump_pressed(player: PlayerChar) -> bool:
	if (player.inputs[PlayerChar.INPUTS.ACTION] == 1 or
	    player.inputs[PlayerChar.INPUTS.ACTION3] == 1):
		return true
	return false

## Homing attack is A
func shadow_homing_attack_pressed(player: PlayerChar) -> bool:
	if player.inputs[PlayerChar.INPUTS.ACTION] == 1:
		return true
	return false
	
## Stomp attack is C
func shadow_stomp_attack_pressed(player: PlayerChar) -> bool:
	if player.inputs[PlayerChar.INPUTS.ACTION3] == 1:
		return true
	return false
	
## Boost is B
func shadow_boost_pressed(player: PlayerChar) -> bool:
	if player.inputs[PlayerChar.INPUTS.ACTION2] == 1:
		return true
	return false

## For reasons I'm not entirely sure of yet, Shadow can boost without a fresh button press while
## airborne.	
func shadow_boost_pressed_or_held(player: PlayerChar) -> bool:
	if player.inputs[PlayerChar.INPUTS.ACTION2] >= 1:
		return true
	return false

#endregion

func shadow_jump_dash(player: PlayerChar):
	# Spawn effect
	var burst = burst.instantiate()
	Global.get_level().add_child(burst)
	burst.global_position = global_position
	
	# play sound
	sfx[2].play() # Jump Dash Sound
	
	# enable wall cling
	cling_enabled = true
	
	player.movement = Vector2(6 * player.get_direction_multiplier() * 60, -2 * 60)
	homing_attack_available = false
	
	# Set animation
	$PlayerAnimation.play("roll")

func shadow_homing_attack(player: PlayerChar):
	# play sound
	sfx[3].play() # Homing Attack sound
	homing_attack_state.set_target(homing_attack_cur_target)
	homing_reticle.set_target(null)
	homing_attack_cur_target = null
	$PlayerAnimation.play("roll")
	player.set_character_action_state(CHAR_STATES.SHADOW_HOMING_ATTACK, Vector2.ZERO, false)
	homing_attack_available = false


## Functions used to apply Shadow's special abilities
#region action_callbacks
func shadow_jump_actions_callback(_state: PlayerState, player: PlayerChar, _delta: float) -> bool:
	if shadow_boost_pressed(player):
		print("Engage Boost!")
		return true
	
	# Don't allow Shadow to use homing attack or stomp if his ability lock has time on it
	if ability_lock_timer > 0.0:
		return true

	if homing_attack_available and shadow_homing_attack_pressed(player):
		if homing_attack_cur_target == null:
			shadow_jump_dash(player)
			return true
		else:
			shadow_homing_attack(player)
			return true
		
	if stomp_available and shadow_stomp_attack_pressed(player) :
		print("Engage Stomp!")
		stomp_available = false # prevent stomp until next landing or reset triggered
		
		$PlayerAnimation.play("stomp")
		vfx_animator.play("stomp")
		sfx[0].play()
		player.movement = Vector2(0,8*60)
		player.set_character_action_state(CHAR_STATES.SHADOW_STOMP, Vector2.ZERO, false)
		return true
	
	# Aim Homing Attack
	homing_attack_cur_target = homing_tracker.calc_scores(global_position, controller_direction)
	if homing_attack_cur_target != homing_reticle.current_target:
		homing_reticle.set_target(homing_attack_cur_target)
	
	return true
	
func shadow_ground_actions_callback(_state: PlayerState, player: PlayerChar, _delta: float) -> bool:
	# I think we need a horrible hack right here for now... or to postpone it for later.
	return true
#endregion

func reset_air_abilities():
	self.homing_attack_available = true
	self.stomp_available = true
	self.cling_enabled = false

func register_state_modifications(player: PlayerChar):
	var jump_state: PlayerState = player.get_state_object(PlayerChar.STATES.JUMP)
	var normal_state: PlayerState = player.get_state_object(PlayerChar.STATES.NORMAL)
	var air_state: PlayerState = player.get_state_object(PlayerChar.STATES.AIR)
	jump_state.register_process_supplement(shadow_jump_actions_callback)
	# Shadow is unique from most characters in that he can do most of his jump actions from a normal
	# air state. He can also cancel moves using other moves.
	air_state.register_process_supplement(shadow_jump_actions_callback)
	normal_state.register_process_supplement(shadow_ground_actions_callback)
	homing_attack_state.register_process_supplement(shadow_jump_actions_callback)
	stomp_state.register_process_supplement(shadow_jump_actions_callback)
	
func handle_bounce():
	reset_air_abilities()
	ability_lock_timer = bounce_lock_time
	pass

class HomingAttackArea extends Area2D:
	pass
