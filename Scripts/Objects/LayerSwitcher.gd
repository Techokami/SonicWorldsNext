@tool
extends Area2D

var texture = load("res://Graphics/EditorUI/layer_switchers.png")

# layer settings, should be self explanatory
@export var size: Vector2i = Vector2i(1, 3):
	set(value):
		size = value.max(Vector2i.ZERO)

enum ORIENTATION { HORIZONTAL, VERTICAL }
@export var orientation: ORIENTATION = ORIENTATION.HORIZONTAL

@export var rightLayer: Global.COLLISION_PLANES = Global.COLLISION_PLANES.LOW:
	set(value):
		rightLayer = value
		if is_node_ready():
			leftLayer = int(value == Global.COLLISION_PLANES.LOW) as Global.COLLISION_PLANES

@export var leftLayer: Global.COLLISION_PLANES = Global.COLLISION_PLANES.HIGH:
	set(value):
		leftLayer = value
		if is_node_ready():
			rightLayer = int(value == Global.COLLISION_PLANES.LOW) as Global.COLLISION_PLANES

@export var onlyOnFloor = false

# list of player contacts
var player_list: Array[PlayerChar] = []

func _ready():
	# set the mask scale to match the visual scale
	$Mask.scale = size
	# make invisible if not a hint
	if not Engine.is_editor_hint():
		visible = false

func _physics_process(_delta):
	for player: PlayerChar in player_list:
		# skip if we only check for grounded players and the player isn't on ground
		if not player.ground and onlyOnFloor:
			continue
		match(orientation):
			ORIENTATION.HORIZONTAL:
				player.collision_plane = rightLayer if player.global_position.x > global_position.x else leftLayer
			ORIENTATION.VERTICAL:
				player.collision_plane = rightLayer if player.global_position.y > global_position.y else leftLayer

func _process(_delta):
	# update for editor
	if Engine.is_editor_hint():
		$Mask.scale = size
		queue_redraw()

func _draw():
	# draw texture based on size, note this is purely for the editor
	for i: int in range(size.x):
		draw_texture_rect_region(texture,
			Rect2(Vector2((-8.0 * size.x) + (i * 16.0), -8.0 * size.y), Vector2(8.0, 16.0 * size.y)),
			Rect2(Vector2(16.0 * orientation, 0.0), Vector2(8.0, 16.0 * size.y)))
	for i: int in range(size.x):
		for j: int in range(size.y):
			draw_texture_rect_region(texture,
				Rect2(Vector2((-8.0 * size.x) + 8.0 + (i * 16.0), (-8.0 * size.y) + 16.0 * j), Vector2(8.0, 8.0)),
				Rect2(Vector2(8.0 + rightLayer * 16.0, 0.0), Vector2(8.0, 8.0)))
			draw_texture_rect_region(texture,
				Rect2(Vector2((-8.0 * size.x) + 8.0 + (i * 16.0), (-8.0 * size.y) + 8.0 + 16.0 * j), Vector2(8.0,8.0)),
				Rect2(Vector2(8.0 + leftLayer * 16.0, 8.0), Vector2(8.0, 8.0)))
	


func _on_layer_switcher_body_entered(player: PlayerChar):
	if not Engine.is_editor_hint() and player not in player_list:
		player_list.append(player)


func _on_layer_switcher_body_exited(player: PlayerChar):
	if not Engine.is_editor_hint():
		player_list.erase(player)
