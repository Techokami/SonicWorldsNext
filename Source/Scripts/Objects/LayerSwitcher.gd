@tool
extends Area2D

var texture = preload("res://Graphics/EditorUI/LayerSwitchers.png");
@export var size = Vector2(1,3);
@export_enum( "Horizontal", "Vertical") var orientation = 0;
@export_enum( "Low", "High") var rightLayer = 0;
@export_enum( "Low", "High") var leftLayer = 1;

func _ready():
	$Mask.scale = size;
	if (!Engine.editor_hint):
		visible = false

func _process(delta):
	if (Engine.editor_hint):
		$Mask.scale = size;
		update();

func _draw():
	for i in range(size.x):
		draw_texture_rect_region(texture,
		Rect2(Vector2((-8*size.x)+(i*16),-8*size.y),Vector2(8,16*size.y)),
		Rect2(Vector2(orientation*16,0),Vector2(8,16*size.y)));
	for i in range(size.x):
		for j in range(size.y):
			draw_texture_rect_region(texture,
			Rect2(Vector2((-8*size.x)+8+(i*16),(-8*size.y)+16*j),Vector2(8,8)),
			Rect2(Vector2(8+rightLayer*16,0),Vector2(8,8)));
			draw_texture_rect_region(texture,
			Rect2(Vector2((-8*size.x)+8+(i*16),(-8*size.y)+8+16*j),Vector2(8,8)),
			Rect2(Vector2(8+leftLayer*16,8),Vector2(8,8)));
	


func _on_LayerSwitcher_body_entered(body):
	if (!Engine.editor_hint):
		if (body.get("defaultLayer") != null && body.get("velocity") != null):
			if (body.velocity.rotated(body.rotation).x > 0):
				body.defaultLayer = rightLayer;
			else:
				body.defaultLayer = leftLayer;
			if (body.has_method("layer_check_casts")):
				body.layer_check_casts()
