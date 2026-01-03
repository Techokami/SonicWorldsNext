## The PlayerAvatar class contains the specific attributes of your character.
## For now this just contains the specific attributes and collision boxes for the character,
## but with future refactoring this could include things like input mappings and per state
## character code.
class_name ShadowAvatar extends PlayerAvatar

var homing_attack_available := true
var stomp_available := true

## The player can cancel homing attack/jump dash with stomp
@export var stomp_cancel := true
## The player can cencel stomp with homing attack/jump dash
@export var homing_attack_cancel := true

enum CHAR_STATES {
	SHADOW_STOMP,
}

@onready var sfx = $SFX.get_children()
@onready var vfx_animator: AnimationPlayer = $Sprite2D/VFXAnimator

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

## Functions used to apply Shadow's special abilities
#region action_callbacks
func shadow_jump_actions_callback(_state: PlayerState, player: PlayerChar, _delta: float):
	if shadow_homing_attack_pressed(player):
		print("Engage Homing Attack / Jump Dash!")
		return true
		
	if shadow_stomp_attack_pressed(player) and stomp_available:
		print("Engage Stomp!")
		stomp_available = false # prevent stomp until next landing or reset triggered
		
		$PlayerAnimation.play("stomp")
		vfx_animator.play("stomp")
		sfx[0].play()
		player.movement = Vector2(0,8*60)
		player.set_character_action_state(CHAR_STATES.SHADOW_STOMP, Vector2.ZERO, true)
		return true
	
	if shadow_boost_pressed(player):
		print("Engage Boost!")
		return true
	
	return true
	
func shadow_ground_actions_callback(_state: PlayerState, player: PlayerChar, _delta: float):
	# I think we need a horrible hack right here for now... or to postpone it for later.
	return true
#endregion

func shadow_reset_abilities(state_exiting: PlayerState, state_entering: PlayerChar.STATES,
		player: PlayerChar, character_state_entering: CHAR_STATES):
	self.homing_attack_available = true
	self.stomp_available = true

func register_state_modifications(player: PlayerChar):
	var jump_state: PlayerState = player.get_state_object(PlayerChar.STATES.JUMP)
	var normal_state: PlayerState = player.get_state_object(PlayerChar.STATES.NORMAL)
	jump_state.register_process_supplement(shadow_jump_actions_callback)
	normal_state.register_process_supplement(shadow_ground_actions_callback)
	normal_state.register_exit_supplement(shadow_reset_abilities)
