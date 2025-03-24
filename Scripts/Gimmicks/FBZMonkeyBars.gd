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
@export var allowDepartWhileMoving = false

## Just like with hanging bar, if this is set to true then the player can connect while moving
## upwards instead of just when falling
@export var onlyActiveMovingDown = true

## Just like with hanging bar, if this is set to true then the player can drop below the gimmick
## instead of jumping upwards off of it by holding down while jumping.
@export var holdDownToDrop = false

var cur_height = initial_height
var offset = Vector2(0 - monkeybarTexture.get_width() / 2, 0)
var linkOffset = Vector2(0 - linkTexture.get_width() / 2, 0)

#signal pressed_with_body(body)
#signal pressed
#signal released

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cur_height = initial_height
	pass


func check_grab(player):
	# We don't grab if the player is on a gimmick already
	if player.get_active_gimmick() != null:
		return false
	# If the gimmick is locked, player won't bind to it
	if player.is_gimmick_locked_for_player(self):
		return false
	# We don't grab if the player is moving upwards and the pole is set not to grab upward moving players.
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
	
func connect_player(player):
	if not player.set_active_gimmick(self):
		return
	
	player.animator.play("hang")
	player.set_state(player.STATES.AIR)

	# Is there anything we need to track as far as variables go? Maybe later.
	pass
	
func disconnect_player(player, mountingAnotherBar):
	if not mountingAnotherBar:
		player.unset_active_gimmick()
		player.animator.play("roll")
		player.set_state(player.STATES.JUMP)
	else:
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var players_to_check
	
	if Engine.is_editor_hint():
		$CollisionObjects.global_position.y = global_position.y + initial_height + 3 + monkeybarTexture.get_height()
		queue_redraw()
		return
		
	#$CollisionObjects.global_position.y = global_position.y + cur_height + 3 + monkeybarTexture.get_height()
	queue_redraw()
	
	players_to_check = $CollisionObjects/MonkeyBarHanger.get_overlapping_bodies()
	for player in players_to_check:
		if check_grab(player):
			connect_player(player)
			continue

func _physics_process(delta: float) -> void:
	var pixels_moved = 0
	# Don't run it if in the editor.
	if Engine.is_editor_hint():
		return
		
	# If player is on gimmick and the target height isn't reached yet...
	if Global.is_any_player_on_gimmick(self) and cur_height != target_height:
		var yMove = target_height - cur_height
		if yMove > 0:
			cur_height = cur_height + lift_speed * delta
			if cur_height > target_height:
				cur_height = target_height
		else:
			cur_height = cur_height - lift_speed * delta
			if cur_height < target_height:
				cur_height = target_height
				
	# If the player is off the gimmick and the gimmick isn't at the initial height...
	if not Global.is_any_player_on_gimmick(self) and cur_height != initial_height:
		var yMove = initial_height - cur_height
		if yMove > 0:
			cur_height = cur_height + lift_speed * delta
			if cur_height > initial_height:
				cur_height = initial_height
		else:
			cur_height = cur_height - lift_speed * delta
			if cur_height < initial_height:
				cur_height = initial_height
	
	# Reset collision object position
	$CollisionObjects.global_position.y = global_position.y + cur_height + 3 + monkeybarTexture.get_height()
	
	for player in Global.get_players_on_gimmick(self):
		var getPose = $CollisionObjects.global_position + Vector2(0, 13)
		
		# verify position change won't clip into objects
		if !player.test_move(player.global_transform,getPose-player.global_position):
			player.global_position = getPose
		
		player.movement = Vector2.ZERO
		player.cam_update()
	
	pass

func draw_tool():
	if (initial_height < target_height):
		draw_line(Vector2(0,initial_height), Vector2(0, target_height), Color(1.0, 0.4, 0.7, 0.55), 3.0)
		
	draw_texture(monkeybarTexture, offset + Vector2(0, initial_height))
		
	for n in range(initial_height, 0, -linkTexture.get_height()):
		draw_texture(linkTexture, Vector2(-linkTexture.get_width() / 2, n - linkTexture.get_height()))
		
	if (initial_height != target_height):
		draw_texture(monkeybarTexture, offset + Vector2(0, target_height), Color(1, 1, 1, 0.35))

func _draw():
	if Engine.is_editor_hint():
		return draw_tool()
		
	draw_texture(monkeybarTexture, offset + Vector2(0, cur_height))
	for n in range(cur_height, 0, -linkTexture.get_height()):
		draw_texture(linkTexture, Vector2(-linkTexture.get_width() / 2, n - linkTexture.get_height()))

# It may be prudent to come back later and refactor this gimmick to use these instead of its own
# process/physics process for player specific actions.
func player_process(player, _delta):
	if player.any_action_pressed():
		disconnect_player(player, false)
		player.movement.y = -player.jmp/2
	pass
	
func player_physics_process(player, _delta):
	pass

# I'll probably need to lock the gimmick here to prevent the same bar from just immediately being
# grabbed if the player is launched off with a spring or something.
func player_force_detach_callback(player):
	pass


func _on_left_linker_body_entered(body: Node2D) -> void:
	# If the player's right brachiate target is already occupied, don't bother.
	if body.get_gimmick_var("brachiate_target_right"):
		return

	print("setting right")
	body.set_gimmick_var("brachiate_target_right", $CollisionObjects/LeftLinker)

func _on_right_linker_body_entered(body: Node2D) -> void:
	# If the player's left brachiate target is already occupied, don't bother.
	if body.get_gimmick_var("brachiate_target_left"):
		return
		
	body.set_gimmick_var("brachiate_target_left", $CollisionObjects/RightLinker)
	print("setting left")

func _on_left_linker_body_exited(body: Node2D) -> void:
	# If I'm not already the player's right brachiate target, don't bother.
	if body.get_gimmick_var("brachiate_target_right") != $CollisionObjects/LeftLinker:
		return
	
	# note: it might be more performant to set to null instead.
	print("unsetting right")
	body.unset_gimmick_var("brachiate_target_right")

func _on_right_linker_body_exited(body: Node2D) -> void:
	# If I'm not already the player's right brachiate left, don't bother.
	if body.get_gimmick_var("brachiate_target_left") != $CollisionObjects/RightLinker:
		return
	
	# note: it might be more performant to set to null instead.
	print("unsetting left")
	body.unset_gimmick_var("brachiate_target_left")
