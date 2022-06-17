tool
extends "res://Scripts/Objects/Hazard.gd"

export var size = Vector2(32,32)

export var lavaGraphicTop = [preload("res://Graphics/Hazards/LavaTop1.png"),preload("res://Graphics/Hazards/LavaTop2.png"),
preload("res://Graphics/Hazards/LavaTop3.png"),preload("res://Graphics/Hazards/LavaTop4.png")]

export var lavaGraphic = [preload("res://Graphics/Hazards/LavaTiles1.png"),preload("res://Graphics/Hazards/LavaTiles2.png"),
preload("res://Graphics/Hazards/LavaTiles3.png"),preload("res://Graphics/Hazards/LavaTiles4.png")]

var frame = 0
var animSpeed = 8

func _ready():
	update_graphics()

func _process(delta):
	if(Engine.editor_hint):
		update_graphics()
	
	# Animation
	var frameUpdate = (floor(frame+delta*animSpeed) != floor(frame))
	frame += delta*animSpeed
	frame = wrapf(frame,0,min(lavaGraphicTop.size(),lavaGraphic.size()))
	
	if frameUpdate:
		$LavaTop.texture = lavaGraphicTop[floor(frame)]
		$LavaTile.texture = lavaGraphic[floor(frame)]

func update_graphics():
	size.x = max(size.x,1)
	size.y = max(size.y,8)
	$LavaTile.region_rect.size = size+Vector2(0,-8)
	$LavaTop.region_rect.size.x = size.x
	$LavaTop.position.y = -round(size.y/2)
	$CollisionShape2D.scale = size/32
	$Collision/CollisionShape2D.scale = $CollisionShape2D.scale
	
