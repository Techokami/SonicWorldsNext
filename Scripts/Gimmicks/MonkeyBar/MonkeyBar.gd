## Brachiatable Hanger Bars (IE Monkeybars)
## Author: DimensionWarped
class_name Brachiatable extends ConnectableGimmick

## Just like with hanging bar, if this is set to false then the player can
## conect to the central hanger while jumping upwards instead instead of 
## only when falling
@export var only_active_moving_down = true

## Lets a player drop through the hanger without getting caught if they are holding down
## Note that the official games handled this a bit differently. Holding *any* direction while
## jumping off of a holdable bar type gimmick would result in all other holdable bar type gimmicks
## being unconnectable in Sonic 2/3K. That's not very intuitive though and leads to some strange
## interactions.
@export var hold_down_to_drop = false

## Adjusts the brachiate animation speed. This means bar to bar transitions will be faster. Note
## that the item you are brachiating to determines the speed, not the item you are brachiating from.
## 1.0 is the base. 2.0 is twice as fast. 0.5 is half as fast.
@export var brachiate_speed = 1.0

## When jumping off while holding a direction, the player will be imparted with
##   some immediate speed
@export var jump_off_speed_boost = 90

## If true, player will not be able to brachiate off of this bar
@export var depart_locked = false

## If true, player will not be able to brachiate on to this bar
@export var impart_locked = false

## If true, monkeybar will be able to pick player off the ground
## TODO NOT IMPLEMENTED - blocked by some necessary collision changes around
## hang animation
@export var picks_up_grounded_player = false

# Note: If you ever wanted to get *really* crazy with this, you could give
# every player character a weight and have a weight mounted value instead. Not
# exactly the most Sonicy thing in the world (Chaotix exampted), but could be
# fun for a puzzle game like Lost Vikings.

# How many players are currently on this monkeybar
var num_mounted = 0

## Raised when num_mounted goes from 0 to 1+
signal became_mounted

## Raised when num_mounted goes from 1+ to 0
signal became_unmounted

## Raised every time the number mounted changes regarldess of count
signal num_mounted_changed(num_mounted : int)

## Raised any time a player connects to the monkeybar
signal player_mounted(player : PlayerChar)

## Raised any time a player disconnects from the monkeybar
signal player_dismounted(player : PlayerChar)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

## Checks if the player can grab onto the hanger portion of the MonkeyBar Gimmick
##   Used when the player is in the jumping state and not mounted on a brachiation surface yet.
func check_grab(player: PlayerChar) -> bool:
	# player won't grab if on the ground
	if player.ground:
		return false
	# We don't grab if the player is on a gimmick already
	if player.get_active_gimmick() != null:
		return false
	# If the gimmick is locked, player won't bind to it
	if player.is_gimmick_locked_for_player(self):
		return false
	# We don't grab if the player is moving upwards and the pole is set not to
	# grab upward moving players.
	if player.movement.y < 0 and only_active_moving_down:
		return false
	# We don't grab when hold_down_to_drop is active and down is held
	if hold_down_to_drop and player.is_down_held():
		return false
	# We don't grab if the player isn't low enough to grab
	if player.global_position.y < $MonkeyBarHanger.global_position.y + 7:
		return false

	# If we didn't hit any of the ejection conditions then we are good to grab
	return true
	
func connect_player(player : PlayerChar, allowSwap: bool = false) -> void:
	if not player.set_active_gimmick(self, allowSwap):
		return
		
	player_mounted.emit(player)

	player.set_state(player.STATES.GIMMICK)
	
	if check_brachiate(player):
		return

	reposition_player_static(player)
	player.get_avatar().get_animator().play("hang")

	# Is there anything we need to track as far as variables go? Maybe later.
	pass
	
func disconnect_player(player : PlayerChar) -> void:
	player.unset_active_gimmick()
	
	if player.get_state() == PlayerChar.STATES.GIMMICK:
		player.get_avatar().get_animator().play("roll")
		player.set_state(player.STATES.JUMP)
		
	player.unset_gimmick_var("brachiate_target_cur")
	player_dismounted.emit(player)
	pass

## Takes a value on a linear distribution from 0 to 1 and spits out
##   The equivalent value if it were on an exponential distribution instead
##   @param value A value to be transformed. This should be between 0 and 1.
##   @param my_exp exponent of the distribution to transform with. Can be anything float really... but
##              if you want to keep it practical, stick to values from 0.1 to 2.
func transform_linear_to_exponential(value : float, my_exp : float) -> float:
	# Convert 0,1 to -1,1
	value = (value * 2.0) - 1.0
	
	# Preserve and flip the sign since fractional exponents don't play well with negative base values
	var my_sign = sign(value)
	value *= my_sign

	# Calculate the exponential distribution transform for the requested value/exponent.
	#   Flip back to negative if necessary.
	value = pow(value, my_exp) * my_sign
	
	# Convert back to 0,1 range
	value = (value + 1.0) / 2.0
	return value

func get_collision_target(hitbox_offset : int) -> Vector2:
	return $MonkeyBarHanger.global_position + Vector2(0, 13 - hitbox_offset)

## This function repositions the player between the current connected brachiato
##   and the one the player is attempting to move to.
func brachiate_reposition_player(player : PlayerChar, player_brachiation_target : Brachiatable):
	var animator = player.get_avatar().get_animator()
	var cur_anim = animator.get_current_animation()
	
	# Don't do anything if the player isn't in the brachiate animation
	if cur_anim != "brachiateLeft" and cur_anim != "brachiateRight":
		return
		
	var percent_complete = animator.get_current_animation_position() / animator.get_current_animation_length()
	
	var hitbox_offset = (player.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL).y / 2.0) - 19 # 0'd for Sonic/Knux, 4 for Tails/Amy I think?
	var getPose = get_collision_target(hitbox_offset)
	var getPose2 = player_brachiation_target.get_collision_target(hitbox_offset)
	var truePose = lerp(getPose, getPose2, transform_linear_to_exponential(percent_complete, 0.65))

	player.set_global_position(truePose)
	player.set_movement(Vector2.ZERO)
	player.cam_update()

## Used when repositioning the player while not brachiating
func reposition_player_static(player : PlayerChar):
		var hitbox_offset = (player.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL).y / 2.0) - 19 # 0'd for Sonic/Knux, 4 for Tails/Amy I think?
		var getPose = $MonkeyBarHanger.global_position + Vector2(0, 13 - hitbox_offset)
		
		# verify position change won't clip into objects
		if !player.test_move(player.global_transform,getPose-player.global_position):
			player.set_global_position(getPose)
		
		player.set_movement(Vector2.ZERO)
		player.cam_update()	
	
func _physics_process(_delta: float) -> void:
	for player : PlayerChar in Global.get_players_on_gimmick(self):
		var player_brachiation_target = player.get_gimmick_var("brachiate_target_cur")
		
		if (player_brachiation_target != null):
			brachiate_reposition_player(player, player_brachiation_target)
			continue
		
		reposition_player_static(player)
	
	pass

## Checks to see if number of mounted players has changed and sends relevant
## signals if so.
func calculate_mount_signals(old_num_mounted : int, new_num_mounted : int) -> void:
	if old_num_mounted == new_num_mounted:
		return
	
	if old_num_mounted == 0 and new_num_mounted > 0:
		became_mounted.emit()
	elif old_num_mounted > 0 and new_num_mounted == 0:
		became_unmounted.emit()

	num_mounted_changed.emit(new_num_mounted)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var players_to_check = $MonkeyBarHanger.get_overlapping_bodies()
	for player : PlayerChar in players_to_check:
		if check_grab(player):
			connect_player(player)
			continue

	# Calculate the number of players mounted on the gimmick and send signals
	# accordingly.
	var players_on_gimmick = Global.get_players_on_gimmick(self)
	calculate_mount_signals(num_mounted, players_on_gimmick.size())
	num_mounted = players_on_gimmick.size()

#enum for arm selection
enum ARM_SELECTION {LEFT, RIGHT}

func brachiate_connect(player : PlayerChar, brachiate_target : Brachiatable) -> void:
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
		player.get_avatar().get_animator().play("brachiateRight", -1,
		                                        brachiate_target.brachiate_speed)
	else:
		player.get_avatar().get_animator().play("brachiateLeft", -1,
		                                        brachiate_target.brachiate_speed)

## Checks if the player can swing like a monkey from one monkeybar to another
## and if so, starts the process.
func check_brachiate(player : PlayerChar):
	# Don't allow check_brachiate while the player is brachiating already!
	var cur_anim = player.get_avatar().get_animator().get_current_animation()
	if cur_anim == "brachiateLeft" or cur_anim == "brachiateRight":
		return false
	
	# If the player isn't brachiating, they might not be allowed to depending on gimmick configuration and status.
	if depart_locked:
		return false

	# TODO It's a small code smell, but it's still a code smell. Too much duplicated code here.
	var brachiate_target_right = player.get_gimmick_var("brachiate_target_right")
	if player.is_right_held() and brachiate_target_right != null and brachiate_target_right.size():
		# Fail safe to prevent a bug where the player just lands on a monkey bar and attempts to go to itself
		if brachiate_target_right[-1] == self:
			return false
		if brachiate_target_right[-1].impart_locked == true:
			return false
		player.set_direction(player.DIRECTIONS.RIGHT)
		brachiate_connect(player, brachiate_target_right[-1])
		return true

	var brachiate_target_left = player.get_gimmick_var("brachiate_target_left")
	if player.is_left_held() and brachiate_target_left != null and brachiate_target_left.size():
		# Fail safe to prevent a bug where the player just lands on a monkey bar and attempts to go to itself
		if brachiate_target_left[-1] == self:
			return false
		if brachiate_target_left[-1].impart_locked == true:
			return false
		player.set_direction(player.DIRECTIONS.LEFT)
		brachiate_connect(player, brachiate_target_left[-1])
		return true
	
	return false

# FUNCTIONS INTENDED FOR USE BY DESIGNERS BELOW

# The most obvious use for set_lock_depart and set_lock_impart is to prevent
# the player from brachiating to a given monkeybar when that monkeybar is being
# moved by something or is just moving quick enough that you think transfering
# to this monkeybar will look awkward. In the provided example, Retractible Chain
# will lock impart and depart while the chain is moving and unlock them when the
# chain stops, all using signals for maximum flexibility.

## Using this function with a value of true makes it so that players on this
## Monkey Bar can't brachiate to another monkeybar and have to jump off instead.
func set_lock_depart(locked : bool):
	self.depart_locked = locked
	
## using this function with a value of true makes it so that players on another
## brachiatable object (such as an adjacent monkeybar) can't brachiate to this
## monkeybar and have to jump off stead.
func set_lock_impart(locked : bool):
	self.impart_locked = locked

## Basic setter for brachiate speed
func set_brachiate_speed(new_speed):
	self.brachiate_speed = new_speed
# SIGNAL HANDLERS BELOW

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

## Locks the gimmick for the player - used if the player is forced off the
## gimmick in a way that might be likely to result in immediate reconnection.
func temp_lock_gimmick(player) -> void:
	var unlock_func = func ():
		player.clear_single_locked_gimmick(self)
	
	var timer:SceneTreeTimer = get_tree().create_timer(0.5, false)
	timer.timeout.connect(unlock_func, CONNECT_DEFERRED)
	
	player.add_locked_gimmick(self)
	pass

func player_process(player: PlayerChar, _delta):
	if player.any_action_pressed():
		player.reset_double_jump_action()
		player.convert_pressed_action_btns_to_held()
		
		disconnect_player(player)
		var new_movement = Vector2()
		new_movement.y = -235 # Note: not different for Knuckles in spite of his jumping issues.
		
		if player.is_left_held():
			new_movement.x = -jump_off_speed_boost
		if player.is_right_held():
			new_movement.x = jump_off_speed_boost
		player.set_movement(new_movement)
		return
		
	if player.ground or player.check_for_ceiling() or \
			player.check_for_back_wall() or player.check_for_front_wall():
		temp_lock_gimmick(player)
		disconnect_player(player)
		return
		
	
	check_brachiate(player)

func handle_animation_finished(player : PlayerChar, animation):
	if animation != "brachiateLeft" and animation != "brachiateRight":
		# This shouldn't happen, but who knows.
		return
		
	var brachiate_target = player.get_gimmick_var("brachiate_target_cur")
	if !brachiate_target:
		# This also shouldn't happen. But I'm too lazy to use asserts.
		return

	brachiate_target.connect_player(player, true)
		
	pass

# I'll probably need to lock the gimmick here to prevent the same bar from just immediately being
# grabbed if the player is launched off with a spring or something.
func player_force_detach_callback(player : PlayerChar):
	# note: it might be more performant to set to null instead.
	temp_lock_gimmick(player)
	disconnect_player(player)
	pass
