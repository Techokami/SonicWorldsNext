@tool
extends Node2D

# Mushroom Hill Zone Horizontal Bars
# Author: DimensionWarped

# TODO: Rework this from almost scratch using ConnectableGimmick

# Warning: In its current implementation, this gimmick may interact poorly with
# some other objects like moving crushers. Make sure you test the interactions of
# anything in close proximity to one of these.

# A little info about how your textures should be arranged:
# The spritesheet needs to be vertically divisible by 3. The width can be
# whatever you like, but the Main_Body portion needs to stretch across the
# entirety of the bar and the texture *should* be imported to repeat. If you
# don't repeat the texture, it will repeat the last column over and over instead
# of repeating the whole width of the body texture.
# The individual parts of the texture should be vertically aligned to link up
# with one another. In the included texture, this means the MainBody is set one
# pixel below the top line.
@export var spriteTexture = load("res://Graphics/Gimmicks/HorizontalBar.png")

# Which sound to play when grabbing the bar
@export var grabSound = preload("res://Audio/SFX/Player/Grab.wav")

# How wide the left anchor is in the sprite in pixels -- specify this if you don't want the drawing
# to have gaps in it.
@export var leftAnchorWidth = 6

# How wide the right anchor is in the sprite in pixels -- specify this if you don't want the drawing
# to have gaps in it.
@export var rightAnchorWidth = 6

# how wide is this bar? Change my size in the editor and I will auto-update!
# NOTE: If you change other parameters, such as the sprite texture or whether or
# not to draw the left/right anchors, you need to modify this value to make it
# update. You can put it back afterwards if you need to.
@export var width = 64

# allow brake - If this parameter is toggled on, players may hold against
# the direction of travel to stop themselves.
@export var allowBrake = false

# How many pixels per second do you want to allow the player to move side to
# side while riding -- affects both the shimmy and the swinging parts of the
# gimmick
@export var shimmySpeed = 60.0 # one pixel per frame at 60fps

# Allows side to side movement on the gimmick for both shimmy and the normal bar
# swing
@export var allowShimmy = true

# Allows the player to cancel the swing by jumping
@export var allowJumpOff = true

# If this is true, the player may hold down when jumping to dismount from the
# gimmick downwards (only applies to shimmy mode) - otherwise the player can
# only jump upwards (which usually means re-entering the gimmick in swing mode)
@export var allowDownwardDetach = false

# If this is false, don't draw the left anchor. The body size will be adjusted accordingly.
@export var drawLeftAnchor = true
# If this is false, don't draw the right anchor. The body size will be adjusted accordingly.
@export var drawRightAnchor = true

# How fast the player must be moving (upwards or downwards) when hitting the
# gimmick to enter the swing animation... usually this is rather low. If this
# value is not met when allowShimmy is on, the player will enter shimmy mode
# instead. If this value is not met and allowShimmy is false, then the player
# will simply bypass the gimmick. In the original implementation, a player meets
# this requirement by falling for more than 32 pixels... or 13 frames of gravity
# accumulating as Y Velocity
@export var swingContactSpeed = 80.0

# If MULTIPLY, multiplies the speed of the incoming character on exit by swingSpeedMultiplyFactor
# If CONSTANT, player always launches at swingSpeedConstant
enum LAUNCH_SPEED_MODE {MULTIPLY, CONSTANT}
@export var launchSpeedMode: LAUNCH_SPEED_MODE

# When launchSpeedMode is constant, this sets the speed at which the player will launch off with.
@export var swingSpeedConstant = 600

# When launchSpeedMode is multiply, this value sets minimum launch off speed.
@export var minSwingSpeed = 400
# When launchSpeedMode is multiply, this value sets maximum launch off speed.
@export var maxSwingSpeed = 720
# When launchSpeedMode is multiply, this is the value that multiplies against your entry speed
@export var multiplySwingSpeed = 1.2

# This value is only used to resize the gimmick in tool mode
var previousWidth = width

# array of players currently interacting with the gimmick
var players = []
var playersMode = []
var playersEntryVel = []


# If player enters with low absolute velocity, enter shimmy mode (unless turned off)
# If player enters from below with high enough volocity, enter launch up mode
# If player enters from above with high enough velocity, enter launch down mode
enum PLAYER_MODE {MONITORING, SHIMMY, LAUNCH_UP, LAUNCH_DOWN}

# Called when the node enters the scene tree for the first time.
func _ready():
	# This value is only used to know when to update the size in tool mode
	$Grab_Sound.stream = grabSound
	previousWidth = width
	resize()
	
func resize():
	var bodyWidth = width
	if drawLeftAnchor:
		bodyWidth -= leftAnchorWidth
	if drawRightAnchor:
		bodyWidth -= rightAnchorWidth
	
	$Main_Body.set_region_rect(Rect2(0, 0, bodyWidth, spriteTexture.get_height() / 3))
	
	$Left_Anchor.visible = drawLeftAnchor
	$Right_Anchor.visible = drawRightAnchor
	
	if not drawLeftAnchor:
		$Main_Body.position.x = 0
	else:
		$Main_Body.position.x = leftAnchorWidth
		
	$Right_Anchor.position.x = leftAnchorWidth + bodyWidth if drawLeftAnchor else bodyWidth

	$Main_Body.set_texture(spriteTexture)
	$Left_Anchor.set_texture(spriteTexture)
	$Left_Anchor.set_region_rect(Rect2(0, spriteTexture.get_height() / 3, leftAnchorWidth, spriteTexture.get_height() / 3))
	$Right_Anchor.set_texture(spriteTexture)
	$Right_Anchor.set_region_rect(Rect2(0, spriteTexture.get_height() / 3 * 2, rightAnchorWidth, spriteTexture.get_height() / 3))
	
	var shape = RectangleShape2D.new()
	var shape2 = RectangleShape2D.new()
	var collision = $Bar_Area/CollisionShape2D
	var collision2 = $Bar_Area_Exit/CollisionShape2D
	shape.size.y = 8
	# We don't want the player overhanging the outside of the gimmick by a lot, so clamp the size of the collision a bit.
	shape.size.x = width - 28
	
	shape2.size.y = shape.size.y + 32
	shape2.size.x = shape.size.x + 8
	
	collision.set_shape(shape)
	collision2.set_shape(shape2)
	if (width % 2 == 0):
		collision.position = Vector2(width / 2.0, 3)
		collision2.position = Vector2(width / 2.0, 3)
	else:
		collision.position = Vector2(((width) / 2.0) + 0.5, 3)
		collision2.position = Vector2((width / 2.0) + 0.5, 3)
	
	
func process_tool():
	if previousWidth != width:
		resize()
		previousWidth = width
	
func _process_player_x_movement(_delta: float, player: PlayerChar, playerIndex: int, xInput: float):
	if (xInput < 0 and player.global_position.x > global_position.x + 16):
		player.movement.x = -shimmySpeed
	elif (xInput > 0 and player.global_position.x < global_position.x + width - 16):
		player.movement.x = shimmySpeed
	else:
		player.movement.x = 0
		
	# While shimmy is allowed, we are also allowed to jump off the gimmick at any time.
	if player.any_action_pressed():
		
		# If down is held and downward detach is allowed, fall down instead.
		if (allowDownwardDetach and player.get_y_input() > 0):
			player.movement.y = 40
		# Otherwise the player jumps upward.
		else:
			player.movement.y = -2 * (player.get_physics().jump_strength / 3.0)
			
		player.groundSpeed = 0
		player.set_state(player.STATES.JUMP)
		player.get_avatar().get_animator().play("roll")
		playersMode[playerIndex] = PLAYER_MODE.MONITORING
		remove_player(player)
		return 1
		
	return 0
		
func _process_player_shimmy_animation(player: PlayerChar):
	var animator: PlayerCharAnimationPlayer = player.get_avatar().get_animator()
	if (player.movement.x == 0):
		animator.seek(0)
		animator.pause()
	else:
		animator.play("hangShimmy", -1, shimmySpeed / 60.0, false)
	
func _process_player_launch_up(player: PlayerChar, playerIndex: int):
	var animator: PlayerCharAnimationPlayer = player.get_avatar().get_animator()
	# If brakes are allowed, we want to allow slamming the breaks a little faster than the upwarda nimation normally plas out.
	if (animator.get_current_animation_position() >= animator.get_current_animation_length() * 0.91)\
		and (player.get_y_input() > 0) and (allowBrake):
		playersMode[playerIndex] = PLAYER_MODE.SHIMMY
		animator.play("hangShimmy", -1, shimmySpeed / 60.0, false)

	# Otherwise we just launch the player on out of the gimmick 
	# DW's note -- this multiplication stuff with the length was stupid of me and I really should have
	# been relying on signals.
	if (animator.get_current_animation_position() >= animator.get_current_animation_length() * 0.97):
		player.set_state(player.STATES.NORMAL)
		# figure out the animation based on the players current animation
		var cur_animation = "walk"
		match(animator.current_animation):
			"walk", "run", "peelOut":
				cur_animation = animator.current_animation
			# if none of the animations match and speed is equal beyond the players top speed, set it to run (default is walk)
			_ when abs(player.groundSpeed) >= min(6*60,player.get_physics().top_speed):
				cur_animation = "run"
		# play player animation
		animator.play("spring", -1, 1, false)
		animator.queue(cur_animation)
		
		if launchSpeedMode == LAUNCH_SPEED_MODE.MULTIPLY:
			player.movement.y = playersEntryVel[playerIndex] * multiplySwingSpeed
			if player.movement.y > -minSwingSpeed:
				player.movement.y = -minSwingSpeed
			elif player.movement.y < -maxSwingSpeed:
				player.movement.y = -maxSwingSpeed
		else:
			player.movement.y = -swingSpeedConstant
		remove_player(player)
		
func _process_player_launch_down(player: PlayerChar, playerIndex: int):
	var animator: PlayerCharAnimationPlayer = player.get_avatar().get_animator()
	# If brakes are allowed, we want to allow slamming the breaks a little faster than the upwarda nimation normally plas out.
	if (animator.get_current_animation_position() >= animator.get_current_animation_length() * 0.91)\
		and (player.get_y_input() < 0) and (allowBrake):
		playersMode[playerIndex] = PLAYER_MODE.SHIMMY
		animator.play("hangShimmy", -1, shimmySpeed / 60.0, false)

	# Otherwise we just launch the player on out of the gimmick
	if (animator.get_current_animation_position() >= animator.get_current_animation_length() * 0.93):
		player.set_state(player.STATES.NORMAL)
		animator.play("walk", -1, 1, false)
		if launchSpeedMode == LAUNCH_SPEED_MODE.MULTIPLY:
			player.movement.y = playersEntryVel[playerIndex] * multiplySwingSpeed
			if player.movement.y < minSwingSpeed:
				player.movement.y = minSwingSpeed
			elif player.movement.y > maxSwingSpeed:
				player.movement.y = maxSwingSpeed
		else:
			player.movement.y = swingSpeedConstant
		remove_player(player)
		
func _process_player_monitoring(player: PlayerChar, playerIndex: int):
	if (player.ground):
		return
	
	if (player.movement.y < -swingContactSpeed):
		player.sprite.flip_h = false

		# This is ok for now, but we need to clean it up.
		player.get_avatar().get_animator().play("swingHorizontalBarMHZ", -1, 1, false)
		player.set_state(player.STATES.GIMMICK)
		player.global_position.y = get_global_position().y + 3
		playersMode[playerIndex] = PLAYER_MODE.LAUNCH_UP
		playersEntryVel[playerIndex] = player.movement.y
		player.movement.y = 0
		$Grab_Sound.play()
			
	elif (player.movement.y > swingContactSpeed):
		player.sprite.flip_h = false
		
		# This is ok for now, but we need to clean it up.
		player.get_avatar().get_animator().play("swingHorizontalBarMHZ", -1, 1, false)
		player.set_state(player.STATES.GIMMICK)
		
		player.global_position.y = get_global_position().y + 3
		playersMode[playerIndex] = PLAYER_MODE.LAUNCH_DOWN
		playersEntryVel[playerIndex] = player.movement.y
		player.movement.y = 0
		$Grab_Sound.play()
				
	else:
		player.sprite.flip_h = false
		player.set_state(player.STATES.GIMMICK)
		player.get_avatar().get_animator().play("hangShimmy", -1, shimmySpeed / 60.0, false)
		player.movement.y = 0
		player.global_position.y = get_global_position().y + 3
		playersMode[playerIndex] = PLAYER_MODE.SHIMMY
		
		$Grab_Sound.play()
	
func process_game(_delta):
	for i in players:
		var playerIndex = players.find(i)
		var xInput = i.get_x_input()
		
		# If the player is in monitoring mode, we check for when to stick them to the bar
		if (playersMode[playerIndex] == PLAYER_MODE.MONITORING):
			_process_player_monitoring(i, playerIndex)
			
		# If the player isn't on the bar yet, we are done with that player.
		if playersMode[playerIndex] == PLAYER_MODE.MONITORING:
			continue
			
		# Eject the player if their state has changed -- this makes the gimmick compatible with damage sources.
		if i.get_state() != i.STATES.GIMMICK:
			remove_player(i)
			continue
		
		# Eject the player if something like a platform picks them up from below.
		if i.ground:
			remove_player(i)
			i.global_position.y = get_global_position().y + 26
			continue
			
		# Eject the player if something like a platform knocks them down from above.
		# Note: Not implemented
		#if false:
		#	remove_player(i)
		#	i.global_position.y = get_global_position().y + 26
		#	continue
			
		# As long as shimmying is allowed, shimmying is allowed in all active modes.
		if (allowShimmy):
			if (_process_player_x_movement(_delta, i, playerIndex, xInput)):
				continue
			
		# Always lock y movement while in any of the modes. Always reset position in case this thing is moving for some reason.
		i.movement.y = 0
		i.global_position.y = get_global_position().y + 3

		match playersMode[playerIndex]:
			PLAYER_MODE.SHIMMY:
				_process_player_shimmy_animation(i)
			PLAYER_MODE.LAUNCH_UP:
				_process_player_launch_up(i, playerIndex)
			PLAYER_MODE.LAUNCH_DOWN:
				_process_player_launch_down(i, playerIndex)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Engine.is_editor_hint():
		process_tool()
	else:
		process_game(_delta)


func _on_bar_area_body_entered(body):
	if !players.has(body):
		players.append(body)
		playersMode.append(PLAYER_MODE.MONITORING)
		playersEntryVel.append(0)

func _on_bar_area_body_exited(body):
	remove_player(body)
	
func remove_player(player):
	var index: int = players.find(player)
	if index != -1:
		# Clean out the player from all player-linked arrays.
		players.erase(player)
		playersMode.remove_at(index)
		playersEntryVel.remove_at(index)
		if player.get_state() == player.STATES.GIMMICK:
			player.set_state(player.STATES.NORMAL)
