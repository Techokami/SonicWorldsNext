@tool
extends CharacterBody2D

static var _orig_texture: Texture2D = null

static var _1up_textures: Array[Texture2D] = []

static var _orig_vframes: int
static var _orig_hframes: int

var physics = false
var grv = 0.21875
var yspeed = 0
var playerTouch: PlayerChar = null
var isActive = true
var Explosion = preload("res://Entities/Misc/BadnickSmoke.tscn")

enum ITEMS {
	# when adding new item types, please make sure
	# 1up is the last item in the list
	RING, SPEED_SHOES, INVINCIBILITY, SHIELD, ELEC_SHIELD, FIRE_SHIELD,
	BUBBLE_SHIELD, SUPER, _1UP, ROBOTNIK
}
@export var item: ITEMS = ITEMS.RING:
	set(value):
		item = value
		if _orig_texture != null:
			_set_item_frame()

func _set_item_frame():
	if item == ITEMS._1UP:
		$Item.hframes = 1
		$Item.vframes = 1
		$Item.frame = 0
		$Item.texture = _1up_textures[0 if Engine.is_editor_hint() else Global.PlayerChar1]
		if !Engine.is_editor_hint():
			$Item.material = Global.get_material_for_character(Global.PlayerChar1)
	else:
		$Item.vframes = _orig_vframes
		$Item.hframes = _orig_hframes
		$Item.frame = item - int(item > ITEMS._1UP) # skip 1up
		$Item.texture = _orig_texture

func _ready():
	var in_editor: bool = Engine.is_editor_hint()
	if _orig_texture == null:
		# back up the original texture and the number of frames in it
		_orig_texture = $Item.texture as Texture2D
		_orig_vframes = $Item.vframes
		_orig_hframes = $Item.hframes
		# resize the 1up textures array
		var char_names: Array = Global.CHARACTERS.keys()
		var num_characters: int = char_names.size()
		_1up_textures.resize(1 if in_editor else num_characters)
		# replace "NONE" with the name of the 1'st character from the list,
		# for development purposes (e.g. when we implement a new game mode
		# and PlayerChar1 is not set, so Godot won't throw a ton of errors)
		char_names[0] = char_names[1]
		# load textures for character-specific frames
		# (if we are in the editor, only load the icon for the 1'st character
		# from the list, as the other icons won't be shown in the editor anyway)
		for i: int in num_characters:
			_1up_textures[i] = load("res://Graphics/Items/monitor_icon_%s.png" % char_names[i].to_lower()) as Texture2D
			if in_editor:
				break

	# when in the editor, frame 0 in the monitor sprite sheet overlaps the item icon
	# with static, which is why we need to set the 1'st frame for the monitor sprite,
	# so the item icon could be seen through the transparent part of that frame
	if in_editor:
		$Monitor.play("", 0.0)
		$Monitor.set_frame_and_progress(1, 0.0)
		set_physics_process(false)

	# set item frame
	_set_item_frame()

func destroy():
	# skip if not activated
	if !isActive:
		return false
	# create explosion
	var explosion = Explosion.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	
	# deactivate
	isActive = false
	physics = false
	
	# set item to have a high Z index so it overlays a lot
	$Item.z_index += 1000
	# play destruction animation
	$Animator.play("DestroyMonitor")
	$SFX/Destroy.play()
	# wait for animation to finish
	await $Animator.animation_changed
	# enable effect
	match (item):
		ITEMS.RING:
			playerTouch.give_ring(10)
		ITEMS.SPEED_SHOES:
			if !playerTouch.get("isSuper"):
				playerTouch.shoeTime = 20
				playerTouch.switch_physics()
				MusicController.play_music_theme(MusicController.MusicTheme.SPEED_UP)
		ITEMS.INVINCIBILITY:
			if !playerTouch.get("isSuper"):
				playerTouch.supTime = 20
				playerTouch.shieldSprite.visible = false # turn off barrier for stars
				playerTouch.get_node("InvincibilityBarrier").visible = true
				MusicController.play_music_theme(MusicController.MusicTheme.INVINCIBLE)
		ITEMS.SHIELD:
			playerTouch.set_shield(playerTouch.SHIELDS.NORMAL)
		ITEMS.ELEC_SHIELD:
			playerTouch.set_shield(playerTouch.SHIELDS.ELEC)
		ITEMS.FIRE_SHIELD:
			playerTouch.set_shield(playerTouch.SHIELDS.FIRE)
		ITEMS.BUBBLE_SHIELD:
			playerTouch.set_shield(playerTouch.SHIELDS.BUBBLE)
		ITEMS.SUPER:
			playerTouch.rings += 50
			if !playerTouch.get("isSuper"):
				playerTouch.set_state(PlayerChar.STATES.SUPER)
		ITEMS._1UP:
			MusicController.play_music_theme(MusicController.MusicTheme._1UP)
		ITEMS.ROBOTNIK:
			playerTouch.hit_player(playerTouch.global_position, Global.HAZARDS.NORMAL, 9, true)

func _physics_process(delta):
	# if physics are on make em fall
	if physics:
		var collide = move_and_collide(Vector2(0,yspeed)*delta)
		yspeed += grv/GlobalFunctions.div_by_delta(delta)
		if collide and yspeed > 0:
			physics = false

# physics collision check, see physics object
func physics_collision(body: PlayerChar, hitVector):
	# Monitor head bouncing
	if hitVector.y < 0:
		yspeed = -1.5*60
		physics = true
		if body.movement.y < 0:
			body.movement.y *= -1
	# check that player has the rolling layer bit set
	elif body.get_collision_layer_value(20):
		# Bounce from below
		if hitVector.x != 0:
			# check conditions for interaction (and the player is the first player)
			if body.movement.y >= 0 and body.movement.x != 0 and body.playerControl == 1:
				playerTouch = body
				destroy()
			else:
				# Stop horizontal movement
				body.movement.x = 0
		# check if player is not an ai or spindashing
		# if they are then destroy
		if body.is_independent() and body.get_state() != body.STATES.SPINDASH:
			body.movement.y = -abs(body.movement.y)
			
			if body.get_state() == PlayerChar.STATES.ROLL:
				body.movement.y = 0
			body.ground = false
			playerTouch = body
			destroy()
		else:
			body.ground = true
			body.movement.y = 0
	return true

# insta shield should break instantly
func _on_InstaArea_area_entered(area):
	if area.get("parent") != null and isActive:
		playerTouch = area.parent
		area.parent.movement.y *= -1
		destroy()
