@tool
extends Area2D

#var texture = preload("res://graphics/editorUI/LayerSwitchers.png")
#@export var size = Vector2(1,3)
#@export_enum("Horizontal", "Vertical") var orientation = 0
#@export_enum("Low", "High") var rightLayer = 0
#@export_enum("Low", "High") var leftLayer = 1
#@export var onlyOnFloor = false
#
#var playerList = []
#
#func _ready():
#	$Mask.scale = size
#	if not Engine.is_editor_hint():
#		visible = false
#
#func _physics_process(delta):
#	if playerList.size() > 0:
#		for i in playerList:
#			if "collissionLayer" in i and "movement" in i and "ground" in i:
#				if i.ground or not onlyOnFloor:
#					match(orientation):
#						0: #Horizontal
#							if (i.global_position.x > global_position.x):
#								i.collissionLayer = rightLayer
#							else:
#								i.collissionLayer = leftLayer
#						1: #Vertical
#							if (i.global_position.y > global_position.y):
#								i.collissionLayer = rightLayer
#							else:
#								i.collissionLayer = leftLayer
#
#func _process(delta):
#	if Engine.is_editor_hint():
#		$Mask.scale = size
#		queue_redraw()
#
#func _draw():
#	if Engine.is_editor_hint():
#		for i in range(size.x):
#			draw_texture_rect_region(texture,
#			Rect2(Vector2((-8*size.x)+(i*16),-8*size.y),Vector2(8,16*size.y)),
#			Rect2(Vector2(orientation*16,0),Vector2(8,16*size.y)))
#		for i in range(size.x):
#			for j in range(size.y):
#				draw_texture_rect_region(texture,
#				Rect2(Vector2((-8*size.x)+8+(i*16),(-8*size.y)+16*j),Vector2(8,8)),
#				Rect2(Vector2(8+rightLayer*16,0),Vector2(8,8)))
#				draw_texture_rect_region(texture,
#				Rect2(Vector2((-8*size.x)+8+(i*16),(-8*size.y)+8+16*j),Vector2(8,8)),
#				Rect2(Vector2(8+leftLayer*16,8),Vector2(8,8)))
#
#
#
#func _on_layer_switcher_body_entered(body):
#	if not Engine.is_editor_hint():
#		if not playerList.has(body):
#			playerList.append(body)
#
#
#func _on_layer_switcher_body_exited(body):
#	if not Engine.is_editor_hint():
#		if playerList.has(body):
#			playerList.erase(body)
