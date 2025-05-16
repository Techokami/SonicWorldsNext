## The PlayerAvatar class contains the specific attributes of your character.
## For now this just contains the specific attributes and collision boxes for the character,
## but with future refactoring this could include things like input mappings and per state
## character code.
class_name PlayerAvatar extends Node2D

# All attributes for this base class are used by Sonic
var hitboxes: Array[Vector2] = [
	Vector2(9,19)*2,  # NORMAL
	Vector2(7,14)*2,  # ROLL
	Vector2(9,11)*2,  # CROUCH
	Vector2(16,14)*2, # GLIDE
	Vector2(16,14)*2  # HORIZONTAL
]

var normal_sprite = preload("res://Graphics/Players/Sonic.png")
var super_sprite = null # A super sprite isn't mandatory.


## This swill slurp up CharacterStates from your PlayerAvatar and turn them into a list
## of states that your avatar can use via get_character_state()
@onready var character_state_list = $CharacterStates.get_children()


## Gets the character-specific PlayerState at the selected index. You should generally supply
## your own enum for this function. Since it's shared between all the characters and the characters
## are expected to have unique state lists, we can't provide a single unifying enum for this
## function. Character states are retrieved from the character_state_list and the
## character_state_list is automatically populated by simply being a child of a PlayerAvatarScene's
## CharacterStates Node.
func get_character_state_object(index: int) -> PlayerState:
	if index < 0:
		push_error("Attempted to get character specific state with negative index")
		return null
		
	if index < character_state_list.size():
		return character_state_list[index]

	push_error("Attempted to get character specifci state outside of range for the PlayerChar")
	return null


## Gets the character animator
func get_animator() -> PlayerCharAnimationPlayer:
	return $PlayerAnimation


## Gets the hitbox for this avatar depending on the standard hitbox type requested
func get_hitbox(hitbox_type: PlayerChar.HITBOXES):
	return hitboxes[hitbox_type]


## Override this to add additions to specific states for a given player -- this is useful for
## adding special abilities. You can also provide a total override to the state code if needed
func register_state_modifications(_player: PlayerChar):
	pass


## Returns the position of the avatar's hands relative to origin (0,0)
## Animations must be set up with a HandsReference position key for this to be particularly
## useful.
## Note: the position will be flipped by X/Y if the sprite is currently flipped.
func get_hands_offset() -> Vector2:
	var hands_reference: Sprite2D = $HandsReference
	var sprite: Sprite2D = $Sprite2D
	var ret_position = hands_reference.position
	if sprite.flip_h:
		ret_position.x *= -1
	if sprite.flip_v:
		ret_position.y *= -1
	return ret_position


## Used to set up the super material for the player
func prep_super_material():
	pass


## Used to send the avatar sprite into super mode
## note: No actual impact on abilities or invincible status -- that's handled in PlayerChar
func go_super():
	var sprite: Sprite2D = $Sprite2D
	var super_animator = $SuperPalette
	if super_sprite:
		sprite.texture = super_sprite
	super_animator.play("Flash")


## Used to end the avatar sprite's super mode
## note: No actual impact on abilities or invincible status -- that's handled in PlayerChar
func end_super():
	var sprite: Sprite2D = $Sprite2D
	var super_animator = $SuperPalette
	if super_sprite:
		sprite.texture = normal_sprite
	super_animator.play("PowerDown")


## Returns the strength at which the PlayerAvatar can break blocks under the condition
## of the supplied player
##
## Retval 0 - Can't break anything special in this state
## Retval 1 - Breaks the walls that you can break just by jumping in Sonic CD
## Retval 2 - Breaks the normal walls into from Green Hill Zone if you are moving fairly quickly
## Retval 5 - Knuckles lightly taps the wall with his fist nipples
##
## Override this function if you have more complex conditions for your character
## (*coughsupersoniccough*). Or less complex (*coughknucklescough*.)
##
## Note that this is only meant for the normal kind of breakable walls that you crash into from
## the left or the right. It isn't blocks that you roll into from above/below or can break by
## bonking from below while in the spring animation or anything like that.
func get_break_power(player: PlayerChar) -> int:
	# Standard wall break from a spindash or high speed roll
	if (player.get_state() == PlayerChar.STATES.ROLL and
			abs(player.movement.x) >= 4.5 * 60):
		return 2
	
	# Weak walls can be destroyed just by jumping or rolling into them. This applies to everyone in
	# the base cast at least.
	if (player.get_state() == PlayerChar.STATES.ROLL or
			player.get_state() == PlayerChar.STATES.JUMP or
			(
				player.get_state() == PlayerChar.STATES.AIR and
				get_animator().current_animation == "roll"
			)
	):	
		return 1
		
	return 0
