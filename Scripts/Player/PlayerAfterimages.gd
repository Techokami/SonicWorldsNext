class_name PlayerAfterimages extends Node

## Number of afterimages displayed after the player.
const NUM_AFTERIMAGES: int = 3

## Number of physics updates between two afterimages.
## For example, [code]UPDATES_PER_AFTERIMAGE = 2[/code]
## means that afterimages appear on each 2'nd physics tick.
const UPDATES_PER_AFTERIMAGE: int = 2

var afterimages: Array[Sprite2D] = []
var tails_afterimages: Array[Sprite2D] = []
var current_idx: int = -1
	
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
		var afterimage: Sprite2D
		var tails_afterimage: Sprite2D
		afterimages.resize(num_slots)
		tails_afterimages.resize(num_slots)
		for i: int in num_slots:
			afterimage = Sprite2D.new()
			tails_afterimage = Sprite2D.new()
			afterimage.visible = false
			tails_afterimage.visible = false
			parent_node.call_deferred("add_child",afterimage)
			afterimage.call_deferred("add_child",tails_afterimage)
			afterimages[i] = afterimage
			tails_afterimages[i] = tails_afterimage
	).call_deferred()

func _process(_delta: float) -> void:
	if current_idx == -1:
		return
	
	# hide everything by default
	for afterimage: Sprite2D in afterimages:
		afterimage.visible = false
	
	# fade afterimages out during the last remaining second
	var fadeout_multiplier: float = min(1.0,get_parent().shoeTime)

	var afterimage: Sprite2D
	var num_displayed: int = 0
	var normalized_idx: int
	# iterate through each `UPDATES_PER_AFTERIMAGE`'th afterimage, starting
	# from the slot next after the last overwritten slot (`current_idx+1`);
	# for example, if the last overwritten slot was 0, the resulting loop range
	# would be `range(1,num_afterimages+0,UPDATES_PER_AFTERIMAGE)`,
	# for 1 it would be `range(2,num_afterimages+1,UPDATES_PER_AFTERIMAGE)`,
	# and so on
	var num_afterimages: int = afterimages.size()
	for i: int in range(current_idx+1,num_afterimages+current_idx,UPDATES_PER_AFTERIMAGE):
		# normalize the index so we'll loop back to index 0
		# after we cross the upper bound
		normalized_idx = i % num_afterimages
		
		afterimage = afterimages[normalized_idx]
		afterimage.visible = true
		num_displayed += 1
		afterimage.modulate.a = 1.0/(NUM_AFTERIMAGES+1)*num_displayed*fadeout_multiplier

func _physics_process(_delta: float) -> void:
	var player: PlayerChar = get_parent()
	if (player.shoeTime <= 0.0 and !player.isSuper) or !player.sprite.visible:
		if current_idx != -1:
			for afterimage: Sprite2D in afterimages:
				afterimage.texture = null
				afterimage.visible = false
			current_idx = -1
		return
	
	current_idx = (current_idx+1) % afterimages.size()
	var afterimage: Sprite2D = afterimages[current_idx]
	_copy_sprite_properties(afterimage,player.sprite)
	
	# also copy Tails' tails
	var player_tails: Sprite2D = player.sprite.get_node_or_null("Tails")
	var tails_afterimage: Sprite2D = tails_afterimages[current_idx]
	if player_tails != null:
		tails_afterimage.visible = player_tails.visible
		if tails_afterimage.visible:
			_copy_sprite_properties(tails_afterimage,player_tails,true)
	else:
		tails_afterimage.visible = false
