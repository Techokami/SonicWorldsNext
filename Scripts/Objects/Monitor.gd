@tool
extends CharacterBody2D

# 0 holds the original items sheet and all the other slots
# hold character-specific 1up frames
static var item_textures: Array[Texture2D] = []

static var _original_hframes: int
static var _original_vframes: int

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
		if !item_textures.is_empty():
			_set_item_frame()

func _set_item_frame():
	if item == ITEMS._1UP:
		$Item.hframes = 1
		$Item.vframes = 1
		$Item.frame = 0
		$Item.texture = item_textures[1 if Engine.is_editor_hint() else Global.PlayerChar1]
	else:
		$Item.vframes = _original_vframes
		$Item.hframes = _original_hframes
		$Item.frame = item - int(item > ITEMS._1UP) # skip 1up
		$Item.texture = item_textures[0]

func _ready():
	# since char_textures is static, the following code will only run once
	if item_textures.is_empty():
		_original_vframes = $Item.vframes
		_original_hframes = $Item.hframes
		# load textures for character-specific frames
		item_textures.resize(Global.CHARACTERS.size())
		item_textures[0] = $Item.texture as Texture2D
		for char_name: String in Global.CHARACTERS.keys():
			if char_name != "NONE":
				item_textures[Global.CHARACTERS[char_name]] = \
					load("res://Graphics/Items/monitor_icon_%s.png" % char_name.to_lower()) as Texture2D
	# if we're in the editor, set the 1'st frame
	# for the monitor itself, so the item icon can be seen
	if Engine.is_editor_hint():
		$Monitor.play("", 0.0)
		$Monitor.set_frame_and_progress(1, 0.0)
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
				Global.currentTheme = 1
				Global.effectTheme.stream = Global.themes[Global.currentTheme]
				Global.effectTheme.play()
		ITEMS.INVINCIBILITY:
			if !playerTouch.get("isSuper"):
				playerTouch.supTime = 20
				playerTouch.shieldSprite.visible = false # turn off barrier for stars
				playerTouch.get_node("InvincibilityBarrier").visible = true
				Global.currentTheme = 0
				Global.effectTheme.stream = Global.themes[Global.currentTheme]
				Global.effectTheme.play()
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
			Global.life.play()
			Global.lives += 1
			Global.effectTheme.volume_db = -100
			Global.music.volume_db = -100
		ITEMS.ROBOTNIK:
			playerTouch.hit_player(playerTouch.global_position, Global.HAZARDS.NORMAL, 9)

func _physics_process(delta):
	if !Engine.is_editor_hint():
		# if physics are on make em fall
		if physics:
			var collide = move_and_collide(Vector2(0,yspeed)*delta)
			yspeed += grv/GlobalFunctions.div_by_delta(delta)
			if collide and yspeed > 0:
				physics = false

# physics collision check, see physics object
func physics_collision(body, hitVector):
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
		if body.playerControl == 1 and body.currentState != body.STATES.SPINDASH:
			body.movement.y = -abs(body.movement.y)
			
			if body.currentState == body.STATES.ROLL:
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
