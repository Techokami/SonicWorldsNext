extends Area2D

var PlatPart = preload("res://Entities/Misc/falling_block_plat.tscn")
@export_node_path("TileMap")var tile
@export var speed = 3.0
@export var soundDelay = 0.5

var players = []
var active = false

var collapseSFX = preload("res://Audio/SFX/Gimmicks/Collapse.wav")

# tile list array, contains an array inside set up like this
# [time left, cell coordinant]
var getTiles = []

func _ready():
	tile = get_node(tile)
	# grab from first layer
	for i in tile.get_used_cells(0):
		# calculate by distance and give co-ordinant
		getTiles.append([i.length()/speed,i])

func _physics_process(delta):
	if !active:
		for i in players:
			if i.ground:
				active = true
				await get_tree().create_timer(soundDelay,false).timeout
				Global.play_sound(collapseSFX)
	else:
		for i in getTiles.size():
			# check that i is still below the tile size
			if i < getTiles.size():
				# decrease timer
				if getTiles[i][0] > 0:
					getTiles[i][0] -= delta
				# remove timer (and array point)
				else:
					# create particle
					var platPart = PlatPart.instantiate()
					add_child(platPart)
					platPart.position += Vector2(getTiles[i][1]*$Tiles.tile_set.tile_size)
					var tileData = $Tiles.get_cell_tile_data(0,getTiles[i][1])
					var tileSource = $Tiles.get_cell_source_id(0,getTiles[i][1])
					platPart.material = tileData.material
					platPart.flip_h = tileData.flip_h
					platPart.flip_v = tileData.flip_v
					platPart.modulate = tileData.modulate
					var tileSetSource = $Tiles.tile_set.get_source(tileSource)
					if tileSetSource is TileSetAtlasSource:
						platPart.texture = tileSetSource.texture
						platPart.region_rect.position = Vector2($Tiles.get_cell_atlas_coords(0,getTiles[i][1]))*Vector2(tileSetSource.texture_region_size)
						platPart.region_rect.size = Vector2(tileSetSource.texture_region_size)
					
					# erase from tilemap
					tile.set_cell(0,getTiles[i][1])
					getTiles.remove_at(i)
					# decrease so we don't skip
					i -= 1


func _on_body_entered(body):
	if !players.has(body):
		players.append(body)

func _on_body_exited(body):
	if players.has(body):
		players.erase(body)
