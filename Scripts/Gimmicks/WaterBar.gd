@tool
extends ConnectableGimmick

# Vertical Swinging Bar from Mushroom Hill Zone
# Author: Sharb (this is a modified version of the Vertical Bar by DimensionWarped)
# Author: DimensionWarped for later revisions and conversion to ConnectableGImmick

## How tall the bar is (automatically resizes in editor)
@export var height: int = 64 :
	set(value):
		var top_sprite: Sprite2D = $VerticalBarSpriteTop
		var middle_sprite: Sprite2D = $VerticalBarSpriteMiddle
		var bottom_sprite: Sprite2D = $VerticalBarSpriteBottom
		
		var top_element_height = top_sprite.get_rect().size.y
		var bottom_element_height = bottom_sprite.get_rect().size.y
		
		if (value < top_element_height + bottom_element_height):
			value = int(top_element_height + bottom_element_height)
		
		var middle_height: int = value - top_element_height - bottom_element_height
		middle_sprite.region_rect.size.y = middle_height
		
		height = value
		
		var col_area: CollisionShape2D = $VerticalBarArea/CollisionShape2D
		
		col_area.shape = RectangleShape2D.new()
		col_area.shape.extents = Vector2(16.0, height / 2.0)
		top_sprite.position.y = (-middle_height / 2.0) - (top_element_height / 2.0)
		bottom_sprite.position.y = (middle_height / 2.0) + (bottom_element_height / 2.0)
		
## How fast the player can move while mounted on the bar
@export var slide_speed: int = 50

## How many seconds the bar can have players on it before it breaks
@export var time_to_break = 3.0

## If enabled, the player can slide off the top or bottom of the bar while sliding up/down. If false
## then the player is prevented from doing so.
@export var allow_slide_off: bool = true

## If true, gimmick breaks on any player detaching
@export var break_on_detach: bool = true

## how many pieces should the sprite split into (vertically)
@export var sprite_splits = 8

## Sound to play when the bar is grabbed
@export var grabSound = preload("res://Audio/SFX/Player/Grab.wav")
## Sound to play when bar broken
@export var collapseSFX = preload("res://Audio/SFX/Gimmicks/Collapse.wav")

# When this exceeds time_to_break, the bar will break and dump all players on it.
var strain: float = 0.0

var players_on_gimmick = 0

# falling sprite particle (repurposed from the falling block platform pieces)
var break_part = preload("res://Entities/Misc/falling_block_plat.tscn")
# Just tracks whether or not the bar is already destroyed
var bar_destroyed = false


# Called when the node enters the scene tree for the first time.
func _ready():
	$Grab.stream = grabSound


# check for players and if the jump button is pressed, release them from the poll
func _process(delta):
	if Engine.is_editor_hint():
		return
	
	# Don't do anything if the bar is destroyed already. Only reason we don't free it is
	# because we don't want to break callbacks anyway.
	if bar_destroyed:
		return
	
	# Connect players
	for player: PlayerChar in $VerticalBarArea.get_overlapping_bodies():
		if player.get_active_gimmick() != null:
			continue
		
		if player.is_gimmick_locked_for_player(self):
			continue
			
		if !check_grab(player):
			continue
		
		# TODO: Add checks for the player's current direction and make this pay attention to that
		#       for the sake of determining an offset before connecting
		
		$Grab.play()
		player.set_hitbox(player.get_predefined_hitbox(PlayerChar.HITBOXES.HORIZONTAL))
		player.set_state(PlayerChar.STATES.GIMMICK, player.get_predefined_hitbox(PlayerChar.HITBOXES.HORIZONTAL))
		player.get_avatar().get_animator().play("clingVerticalBar")
		
		player.set_movement(Vector2(0, 0))
			
		var avatar: PlayerAvatar = player.get_avatar()
		var offset = avatar.get_hands_offset()
		
		player.set_active_gimmick(self)
		players_on_gimmick += 1
		
		player.global_position.x = global_position.x - offset.x
		player.global_position.y = min(player.global_position.y, global_position.y + height / 2.0 - 8)
		player.global_position.y = max(player.global_position.y, global_position.y - height / 2.0 + 8)

	if players_on_gimmick > 0:
		strain += delta
	
	if players_on_gimmick == 0:
		strain = 0.0
	
	if strain >= time_to_break:
		destroy_bar()


func destroy_bar():
	if bar_destroyed:
		return
	
	bar_destroyed = true
	
	# Object References
	var bot_sprite: Sprite2D = $VerticalBarSpriteBottom
	var mid_sprite: Sprite2D = $VerticalBarSpriteMiddle
	var top_sprite: Sprite2D = $VerticalBarSpriteTop
	var collider: Area2D = $VerticalBarArea
	var release_direction = 1.0
	
	# Play the destroy sound
	Global.play_sound(collapseSFX)
	
	# Turn off the collider
	collider.monitoring = false
	
	# Remove all the normal sprites
	bot_sprite.visible = false
	mid_sprite.visible = false
	top_sprite.visible = false
	
	# Remove all players
	for player: PlayerChar in Global.get_players_on_gimmick(self):
		if (player.get_direction() == PlayerChar.DIRECTIONS.LEFT):
			release_direction = -1.0
		remove_player(player)
	
	# Create debris sprites
	for i in sprite_splits:
		var part: FallingBlock = break_part.instantiate()
		part.texture = mid_sprite.texture
		part.centered = true
		var split_height = height / sprite_splits
		
		# set position and source sprite
		part.region_rect.position = Vector2(0, split_height)
		part.region_rect.size = Vector2(mid_sprite.region_rect.size.x, split_height)
		
		# add to scene
		add_child(part)
		# set to position
		part.global_position = global_position
		part.global_position.y += (0.5 * height) - (i *  split_height) - 0.5 * split_height
		# set the velocity
		part.velocity = Vector2(release_direction*220, 0)
		# Reduce the gravity since this is usually in a current stream
		part.gravity = 50
		# Using the release delay means some blocks don't immediately start moving.
		part.release_delay = randf_range(-0.10, 0.25)


func player_physics_process(player: PlayerChar, _delta : float):
	# Drop all the speed values to 0 to prevent issues.
	player.set_ground_speed(0)
	player.movement.x = 0
	
	player.cam_update()


func player_process(player: PlayerChar, _delta : float):
	if player.any_action_pressed():
		remove_player(player)
	
	# Allow the player to slide up and down.
	player.movement.y = player.get_y_input() * slide_speed
	
	# Continually reposition the player based on the hands offset
	var avatar: PlayerAvatar = player.get_avatar()
	var offset = avatar.get_hands_offset()
	player.global_position.x = global_position.x - offset.x
	
	# If the player moves past the edge of the bar, they slip off.
	if player.global_position.y < global_position.y - height / 2.0 + 8:
		if allow_slide_off:
			remove_player(player)
		else:
			player.global_position.y = global_position.y - height / 2.0 + 8
	elif player.global_position.y > global_position.y + height / 2.0 - 8:
		if allow_slide_off:
			remove_player(player)
		else:
			player.global_position.y = global_position.y + height / 2.0 - 8


func check_grab(player: PlayerChar):

	# Don't grab if the player isn't in the right x/y position
	if player.global_position.y < global_position.y - height / 2.0 + 4.0:
		return false
	elif player.global_position.y > global_position.y + height / 2.0 - 4.0:
		return false
	
	# Don't grab until the player is pretty far behind the bar
	if player.get_movement().x > 0 and player.global_position.x < global_position.x + 22:
		return false
		
	if player.get_movement().x < 0 and player.global_position.x > global_position.x - 22:
		return false

	
	return true


func remove_player(player: PlayerChar):
	# reset player animation
	player.get_avatar().get_animator().play("current")
	player.set_state(PlayerChar.STATES.AIR, player.get_predefined_hitbox(PlayerChar.HITBOXES.ROLL))
	player.unset_active_gimmick()
	player.timed_gimmick_lock(self, 0.5)
	players_on_gimmick -= 1
	
	if break_on_detach and !bar_destroyed:
		destroy_bar()

func _draw() -> void:
	pass
