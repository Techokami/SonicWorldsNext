# Flying Battery Zone Monkey Bars
# Also does Mystic Cave Zone hanging vines and switches
# by DimensionWarped (March 2025)

@tool
extends Node2D

## How far the monkey bar is from its ceiling initially (A lower value is closer to the ceiling)
@export_range(0,2000) var initial_height: int = 6

## How far the monkey bar should be from its ceiling after the player has been on it.
## Keep it the same as initial_height if you don't want the monkey bar to move
@export_range(0,2000) var target_height: int = 6

## How many pixels per reference time should the lift travel to reach the target height?
@export_range(0,400) var lift_speed: int = 30

## What graphic to use for the Monkey Bar component
@export var monkeybarTexture: Texture2D = preload("res://Graphics/Gimmicks/FBZMonkeyBar.png")
@export var linkTexture: Texture2D = preload("res://Graphics/Gimmicks/FBZMonkeyBarLink.png")

## Can the player start transitioning to another monkey bar object from this monkey bar object
## before the monkey bar reaches its target height?
## XXX TODO Not implemented yet
@export var allowDepartBrachiateWhileMoving = false

## Can the palyer start transitioning to this monkey bar object from another monkey bar object
## when the monkey bar is not at its initial height?
## XXX TODO Not implemented yet
@export var allowReceiveBrachiateWhileMoved = false

## Just like with hanging bar, if this is set to true then the player can connect while moving
## upwards instead of just when falling
@export var onlyActiveMovingDown = true

## Just like with hanging bar, if this is set to true then the player can drop below the gimmick
## instead of jumping upwards off of it by holding down while jumping.
## XXX TODO Not implemented yet... requires per player gimmick lockout.
@export var holdDownToDrop = false

## Adjusts the brachiate animation speed. This means bar to bar transitions will be faster. Note
## that the item you are brachiating to determines the speed, not the item you are brachiating from.
## 1.0 is the base. 2.0 is twice as fast. 0.5 is half as fast.
@export var brachiateSpeed = 1.0

## When jumping off while holding a direction, the player will be imparted with
##   some immediate speed
@export var jumpOffSpeedBoost = 90

## Optionally set sound to play when making contact
@export var grabSound = preload("res://Audio/SFX/Player/Grab.wav")
## Optionally set a random pitch change to make grab sounds less annoying when played sequentially.
@export var grabSoundPitchRange = 0.2

## Optionally set sound to play when the gimmick is moving
@export var liftSound = preload("res://Audio/SFX/Gimmicks/CableLift.wav")
## Sets the distance at which the lift sound falls off
@export var liftSoundDistance = 2000

var cur_height = initial_height
var offset = Vector2(0 - monkeybarTexture.get_width() / 2.0, 0)
var linkOffset = Vector2(0 - linkTexture.get_width() / 2.0, 0)

var is_moving = false

#signal pressed_with_body(body)
#signal pressed
#signal released

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cur_height = initial_height
	$GrabStreamPlayer.stream = grabSound
	$CableStreamPlayer.stream = liftSound
	$CableStreamPlayer.set_max_distance(liftSoundDistance)
	pass
	
## Checks if the player can grab onto the hanger portion of the MonkeyBar Gimmick
##   Used when the player is in the jumping state and not mounted on a brachiation surface yet.
func check_grab(player):
	# We don't grab if the player is on a gimmick already
	if player.get_active_gimmick() != null:
		return false
	# If the gimmick is locked, player won't bind to it
	if player.is_gimmick_locked_for_player(self):
		return false
	# We don't grab if the player is moving upwards and the pole is set not to
	# grab upward moving players.
	if player.movement.y < 0 and onlyActiveMovingDown:
		return false
	# We don't grab when holdDownToDrop is active and down is held
	if holdDownToDrop and player.is_down_held():
		return false
	# We don't grab if the player isn't low enough to grab
	if player.global_position.y < $CollisionObjects.global_position.y + 7:
		return false

	# If we didn't hit any of the ejection conditions then we are good to grab
	return true
	
func connect_player(player, allowSwap=false):
	if not player.set_active_gimmick(self, allowSwap):
		return
		
	$GrabStreamPlayer.pitch_scale = randf_range(1 - grabSoundPitchRange, 1 + grabSoundPitchRange)
	$GrabStreamPlayer.play()
		
	if check_brachiate(player):
		return

	player.animator.play("hang")
	player.set_state(player.STATES.AIR)

	# Is there anything we need to track as far as variables go? Maybe later.
	pass
	
func disconnect_player(player):
	player.unset_active_gimmick()
	player.animator.play("roll")
	player.set_state(player.STATES.JUMP)
	player.unset_gimmick_var("brachiate_target_cur")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var players_to_check
	
	if Engine.is_editor_hint():
		$CollisionObjects.global_position.y = global_position.y + initial_height + 3 + monkeybarTexture.get_height()
		queue_redraw()
		return
		
	queue_redraw()
	
	players_to_check = $CollisionObjects/MonkeyBarHanger.get_overlapping_bodies()
	for player in players_to_check:
		if check_grab(player):
			connect_player(player)
			continue

func get_target_y_pos_for_hanger_per_player(player):
	# XXX Not ready
	var hitbox_offset = (player.currentHitbox.NORMAL.y / 2.0) - 19 # 0'd for Sonic/Knux, 4 for Tails/Amy I think?
	var getPose = $CollisionObjects.global_position + Vector2(0, 13 - hitbox_offset)
	pass

func get_collision_target(hitbox_offset):
	return $CollisionObjects.global_position + Vector2(0, 13 - hitbox_offset)

## Takes a value on a linear distribution from 0 to 1 and spits out
##   The equivalent value if it were on an exponential distribution instead
##   @param value A value to be transformed. This should be between 0 and 1.
##   @param exp exponent of the distribution to transform with. Can be anything float really... but
##              if you want to keep it practical, stick to values from 0.1 to 2.
func transform_linear_to_exponential(value, exp):
	# Convert 0,1 to -1,1
	value = (value * 2.0) - 1.0
	
	# Preserve and flip the sign since fractional exponents don't play well with negative base values
	var sign
	if value < 0:
		sign = -1.0
		value *= sign
	else:
		sign = 1.0

	# Calculate the exponential distribution transform for the requested value/exponent.
	#   Flip back to negative if necessary.
	value = pow(value, exp) * sign
	
	# Convert back to 0,1 range
	value = (value + 1.0) / 2.0
	return value

## This function repositions the player between the current connected brachiato
##   and the one the player is attempting to move to.
func brachiate_reposition_player(player, player_brachiation_target):
	var cur_anim = player.animator.get_current_animation()

	# Don't do anything if the player isn't in the brachiate animation
	if cur_anim != "brachiateLeft" and cur_anim != "brachiateRight":
		return
		
	var percent_complete = player.animator.get_current_animation_position() / player.animator.get_current_animation_length()
	var hitbox_offset = (player.currentHitbox.NORMAL.y / 2.0) - 19 # 0'd for Sonic/Knux, 4 for Tails/Amy I think?
	var getPose = get_collision_target(hitbox_offset)
	var getPose2 = player_brachiation_target.get_collision_target(hitbox_offset)
	var truePose = lerp(getPose, getPose2, transform_linear_to_exponential(percent_complete, 0.65))
		
	player.global_position = truePose
		
	player.movement = Vector2.ZERO
	player.cam_update()

func _physics_process(delta: float) -> void:
	# Don't run it if in the editor.
	if Engine.is_editor_hint():
		return

	# XXX TODO This whole block until the next XXX block is a code smell
	# If player is on gimmick and the target height isn't reached yet...
	if Global.is_any_player_on_gimmick(self) and cur_height != target_height:
		var yMove = target_height - cur_height
		if yMove > 0:
			cur_height = cur_height + lift_speed * delta
			if !is_moving:
				$CableStreamPlayer.play()
			is_moving = true
			if cur_height >= target_height:
				cur_height = target_height
				is_moving = false
				$CableStreamPlayer.stop()
		else:
			cur_height = cur_height - lift_speed * delta
			if !is_moving:
				$CableStreamPlayer.play()
			is_moving = true
			if cur_height <= target_height:
				cur_height = target_height
				is_moving = false
				$CableStreamPlayer.stop()
				
	# If the player is off the gimmick and the gimmick isn't at the initial height...
	if not Global.is_any_player_on_gimmick(self) and cur_height != initial_height:
		var yMove = initial_height - cur_height
		if yMove > 0:
			cur_height = cur_height + lift_speed * delta
			if !is_moving:
				$CableStreamPlayer.play()
			is_moving = true
			if cur_height >= initial_height:
				cur_height = initial_height
				is_moving = false
				$CableStreamPlayer.stop()
		else:
			cur_height = cur_height - lift_speed * delta
			if !is_moving:
				$CableStreamPlayer.play()
			is_moving = true
			if cur_height <= initial_height:
				cur_height = initial_height
				is_moving = false
				$CableStreamPlayer.stop()
				
	# XXX #
	
	# Reset collision object position
	$CollisionObjects.global_position.y = global_position.y + cur_height + 3 + monkeybarTexture.get_height()

	for player in Global.get_players_on_gimmick(self):
		var player_brachiation_target = player.get_gimmick_var("brachiate_target_cur")
		
		if (player_brachiation_target != null):
			brachiate_reposition_player(player, player_brachiation_target)
			continue
		
		var hitbox_offset = (player.currentHitbox.NORMAL.y / 2.0) - 19 # 0'd for Sonic/Knux, 4 for Tails/Amy I think?
		var getPose = $CollisionObjects.global_position + Vector2(0, 13 - hitbox_offset)
		
		# verify position change won't clip into objects
		if !player.test_move(player.global_transform,getPose-player.global_position):
			player.global_position = getPose
		
		player.movement = Vector2.ZERO
		player.cam_update()
	
	pass

## Draws the object within the editor
##   Draws some hints that include a phantom image of where the target of the target position is
##   along with a connective line if that target is below the initial position.
func draw_tool():
	if (initial_height < target_height):
		draw_line(Vector2(0,initial_height), Vector2(0, target_height), Color(1.0, 0.4, 0.7, 0.55), 3.0)
		
	draw_texture(monkeybarTexture, offset + Vector2(0, initial_height))
	
	for n in range(initial_height, 0, -linkTexture.get_height()):
		draw_texture(linkTexture, Vector2(-linkTexture.get_width() / 2, n - linkTexture.get_height()))
	
	if (initial_height != target_height):
		draw_texture(monkeybarTexture, offset + Vector2(0, target_height), Color(1, 1, 1, 0.35))

## Draws the object
##   The most complex thing about drawing this thing is iterating through the length of the chain
##   and drawing 
func _draw():
	if Engine.is_editor_hint():
		return draw_tool()

	draw_texture(monkeybarTexture, offset + Vector2(0, cur_height))
	for n in range(cur_height, 0, -linkTexture.get_height()):
		draw_texture(linkTexture, Vector2(-linkTexture.get_width() / 2, n - linkTexture.get_height()))

func player_process_brachiating(player, brachiation_target, delta):
	if brachiation_target.global_position.x < player.global_position.x:
		player.direction = -1
		player.sprite.flip_h = 1
	else:
		player.direction = 1
		player.sprite.flip_h = 0
	pass
	
#enum for arm selection
enum ARM_SELECTION {LEFT, RIGHT}

func brachiate_connect(player, brachiate_target):
	var animator = player.animator
	var active_brachiator = self
	
	# Set the brachiate target so that the player will begin brachiation on the next pass
	player.set_gimmick_var("brachiate_target_cur", brachiate_target)
	
	# Pick an arm... we should alternate arms until the player gets off. All characters
	# Start off with their right arm... though you could reverse this by changing the
	# brachiate_right animation or by tweaking this code of course.
	var last_arm = player.get_gimmick_var("brachiate_arm")
	var next_arm = ARM_SELECTION.RIGHT
	if last_arm == null:
		player.set_gimmick_var("brachiate_arm", ARM_SELECTION.RIGHT)
	elif last_arm == ARM_SELECTION.RIGHT:
		player.set_gimmick_var("brachiate_arm", ARM_SELECTION.LEFT)
		next_arm = ARM_SELECTION.LEFT
	else:
		player.set_gimmick_var("brachiate_arm", ARM_SELECTION.RIGHT)

	# Play the animation associated with your current brachiation arm
	if next_arm == ARM_SELECTION.RIGHT:
		player.animator.play("brachiateRight", -1, brachiate_target.brachiateSpeed)
	else:
		player.animator.play("brachiateLeft", -1, brachiate_target.brachiateSpeed)

func check_brachiate(player):
	# Don't allow check_brachiate while the player is brachiating already!
	var cur_anim = player.animator.get_current_animation()
	if cur_anim == "brachiateLeft" or cur_anim == "brachiateRight":
		return false
	
	# If the player isn't brachiating, they might not be allowed to depending on gimmick configuration and status.
	if not allowDepartBrachiateWhileMoving and cur_height != target_height:
		return false
	
	var brachiate_target_right = player.get_gimmick_var("brachiate_target_right")
	if player.is_right_held() and brachiate_target_right != null and brachiate_target_right.size():
		brachiate_connect(player, brachiate_target_right[0])
		return true

	var brachiate_target_left = player.get_gimmick_var("brachiate_target_left")
	if player.is_left_held() and brachiate_target_left != null and brachiate_target_left.size():
		brachiate_connect(player, brachiate_target_left[0])
		return true
	
	return false

# It may be prudent to come back later and refactor this gimmick to use these instead of its own
# process/physics process for player specific actions.
func player_process(player, delta):
	if player.any_action_pressed():
		disconnect_player(player)
		player.movement.y = -235 # Note: not different for Knuckles in spite of his jumping issues.
		if player.is_left_held():
			player.movement.x -= jumpOffSpeedBoost
		if player.is_right_held():
			player.movement.x = jumpOffSpeedBoost
		return
		
	check_brachiate(player)

func player_physics_process(_player, _delta):
	pass

# I'll probably need to lock the gimmick here to prevent the same bar from just immediately being
# grabbed if the player is launched off with a spring or something.
func player_force_detach_callback(player):
	# note: it might be more performant to set to null instead.
	player.unset_gimmick_var("brachiate_target_cur")
	pass

func handle_animation_finished(player, animation):
	if animation != "brachiateLeft" and animation != "brachiateRight":
		# This shouldn't happen, but who knows.
		return
		
	var brachiate_target = player.get_gimmick_var("brachiate_target_cur")
	if !brachiate_target:
		# This also shouldn't happen. But I'm too lazy to use asserts.
		return

	brachiate_target.connect_player(player, true)
		
	pass
	
## Sets the right brachiation target for a player to touches the left side linker
func _on_left_linker_body_entered(body: Node2D) -> void:
	var brachiate_targets_right = body.get_gimmick_var("brachiate_target_right")
	if brachiate_targets_right == null:
		body.set_gimmick_var("brachiate_target_right", [self])
	else:
		brachiate_targets_right.append(self)

## Sets the left brachiation target for a player to touches the right side linker
func _on_right_linker_body_entered(body: Node2D) -> void:
	var brachiate_targets_left = body.get_gimmick_var("brachiate_target_left")
	if brachiate_targets_left == null:
		body.set_gimmick_var("brachiate_target_left", [self])
	else:
		brachiate_targets_left.append(self)

## Disconnects the right brachiation target for a player that leaves the left side linker
func _on_left_linker_body_exited(body: Node2D) -> void:
	var brachiate_targets_right = body.get_gimmick_var("brachiate_target_right")
	if brachiate_targets_right != null:
		brachiate_targets_right.erase(self)

## Disconnects the left brachiation target for a player that leaves the right side linker
func _on_right_linker_body_exited(body: Node2D) -> void:
	var brachiate_targets_left = body.get_gimmick_var("brachiate_target_left")
	if brachiate_targets_left != null:
		brachiate_targets_left.erase(self)
