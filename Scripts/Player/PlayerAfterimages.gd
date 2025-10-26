class_name PlayerAfterimages extends Node

## Number of afterimages displayed after the player.
const NUM_AFTERIMAGES: int = 3

## Number of afterimages generated per second.
const AFTERIMAGES_PER_SECOND: int = 30

## Number of physics updates between two displayed afterimages.[br]
## [b]NOTE:[/b] This value is calculated automatically based on
## [member Engine.physics_ticks_per_second] and [member AFTERIMAGES_PER_SECOND].
var UPDATES_PER_AFTERIMAGE: int = Engine.physics_ticks_per_second/AFTERIMAGES_PER_SECOND

class _Afterimage extends Sprite2D:
	var tails_sprite: Sprite2D = Sprite2D.new()

var afterimages: Array[_Afterimage] = []
var active: bool = false
	
func _copy_sprite_properties(dest: Sprite2D, source: Sprite2D, tails: bool = false) -> void:
	dest.texture = source.texture
	dest.hframes = source.hframes
	dest.vframes = source.vframes
	dest.frame = source.frame
	dest.offset = source.offset
	dest.global_position = source.global_position
	if tails:
		dest.rotation = source.rotation
		dest.scale = source.scale
	else:
		dest.global_rotation = source.global_rotation
		dest.flip_h = source.flip_h
		dest.flip_v = source.flip_v

func _init() -> void:
	(func() -> void:
		var player: PlayerChar = get_parent()
		if player.playerControl != 1:
			queue_free()
			return
		var parent_node: Node = player.get_parent()
		var num_slots: int = NUM_AFTERIMAGES*UPDATES_PER_AFTERIMAGE+1
		var afterimage: _Afterimage
		afterimages.resize(num_slots)
		for i: int in num_slots:
			afterimage = _Afterimage.new()
			afterimage.visible = false
			afterimage.tails_sprite.visible = false
			parent_node.call_deferred("add_child",afterimage)
			afterimage.call_deferred("add_child",afterimage.tails_sprite)
			afterimages[i] = afterimage
	).call_deferred()

func _process(_delta: float) -> void:
	if !active:
		return
	
	# hide everything by default
	for afterimage: Sprite2D in afterimages:
		afterimage.visible = false
	
	# fade afterimages out during the last remaining second
	var fadeout_multiplier: float = min(1.0,get_parent().shoeTime)
	
	# mark each UPDATES_PER_AFTERIMAGE'th image as visible
	var afterimage: Sprite2D
	var num_displayed: int = 0
	var last_slot_idx: int = afterimages.size()-1
	for i: int in last_slot_idx:
		afterimage = afterimages[i]
		if i % UPDATES_PER_AFTERIMAGE != 0:
			afterimage.visible = false
			continue
		afterimage.visible = true
		num_displayed += 1
		afterimage.modulate.a = 1.0/(NUM_AFTERIMAGES+1)*num_displayed*fadeout_multiplier
	afterimages[last_slot_idx].visible = false

func _physics_process(_delta: float) -> void:
	var player: PlayerChar = get_parent()
	if (player.shoeTime <= 0.0 and !player.isSuper) or !player.sprite.visible:
		if active:
			for afterimage: Sprite2D in afterimages:
				afterimage.texture = null
				afterimage.visible = false
			active = false
		return
	active = true
	
	# pick the first element to overwrite the afterimage in it later
	var afterimage: _Afterimage = afterimages[0]
	
	# shift all elements back by 1 and move the first element into the last slot
	afterimages.append(afterimages.pop_front())
	
	# don't display the afterimage if the player is invisible
	# (e.g. entered a Giant Ring) or if they're interacting with a gimmick
	if !player.visible or \
	   player.get_state() == PlayerChar.STATES.GIMMICK or \
	   player.get_active_gimmick() != null:
		afterimage.texture = null
		afterimage.tails_sprite.visible = false
		return
	
	# copy the properties of the player's current sprite into the picked afterimage
	_copy_sprite_properties(afterimage,player.sprite)
	
	# also copy Tails' tails
	var player_tails: Sprite2D = player.sprite.get_node_or_null("Tails")
	if player_tails != null:
		afterimage.tails_sprite.visible = player_tails.visible
		if player_tails.visible:
			_copy_sprite_properties(afterimage.tails_sprite,player_tails,true)
	else:
		afterimage.tails_sprite.visible = false
