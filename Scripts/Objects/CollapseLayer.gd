extends Area2D

# collapsing platform code by sharb + caverns4
# conversion and documentation by DimensionWarped
#
# Replaces CollapsePlatform.gd in GD 4.3 -- old consumers need to have their
# tilemaps converted to tile map layers in order for this script to work.
#
# To do this:
# 1. Detach the original CollapsePlatform.gd script from your
#    collapsing platform node.
# 2. Extract the layers from the the tilemap using the screwdriver/spanner menu
#    from the tilemap editor.
# 3. Reparent the extracted layers so that they aren't children of the tilemap.
# 4. Delete the deprecated tilemap object.
# 5. Attach this script (CollapseLayer.gd) to your node from which you
#    previously detached CollapsePlatform.gd in step 1
# 6. Lastly, in the property insepctor for your main collapsing platform node,
#    pick the tilemap layer you extracted to be the new assigned 'Tile'.

# platform particle
var PlatPart = preload("res://Entities/Misc/falling_block_plat.tscn")

# tilemap source to pull from
@export_node_path("TileMapLayer") var tile
# how fast the platform collapses
@export var speed = 3.0
# how long to wait before playing the sound
@export var soundDelay = 0.5

# player array
var players = []

# used for detecting if the platform is collapsing
var active = false

# the collapsing sound
@export var collapseSFX = preload("res://Audio/SFX/Gimmicks/Collapse.wav")

# tile list array, contains an array inside set up like this
# [time left, cell coordinant]
var getTiles = []

func _ready():
	# set the tile reference to the tilemap
	tile = get_node(tile)
	# grab from first layer
	for i in tile.get_used_cells():
		# calculate by distance and give co-ordinant
		getTiles.append([i.length()/speed,i])

func _physics_process(delta):
	# check if to activate
	if !active:
		# if we can detect any players and they're on the flor, activate
		for i in players:
			# do a active check to prevent the sound playing twice
			if i.ground and !active:
				active = true
				# wait for sound delay
				await get_tree().create_timer(soundDelay,false).timeout
				# play sound globally (prevents sound overlap, aka loud sounds)
				Global.play_sound(collapseSFX)
	else:
		# loop through and generate a tile particle
		for i in getTiles.size():
			# check that i is still below the tile size
			if i < getTiles.size():
				# decrease timer if above 0
				if getTiles[i][0] > 0:
					getTiles[i][0] -= delta
				# remove timer (and array point) and create the block particle
				else:
					# create particle (we pull from the tilemap)
					var platPart = PlatPart.instantiate()
					add_child(platPart)
					# set position
					platPart.position += Vector2(getTiles[i][1]*tile.tile_set.tile_size)+tile.position
					# references for thet ile
					var tileData = tile.get_cell_tile_data(getTiles[i][1])
					var tileSource = tile.get_cell_source_id(getTiles[i][1])
					# grab any materials
					platPart.material = tileData.material
					# check if the tile's been flipped
					platPart.flip_h = tileData.flip_h
					platPart.flip_v = tileData.flip_v
					# check for colour changes
					platPart.modulate = tileData.modulate
					
					# grab the image and the position and size
					var tileSetSource = tile.tile_set.get_source(tileSource)
					if tileSetSource is TileSetAtlasSource:
						platPart.texture = tileSetSource.texture
						platPart.region_rect.position = Vector2(tile.get_cell_atlas_coords(getTiles[i][1]))*Vector2(tileSetSource.texture_region_size)
						platPart.region_rect.size = Vector2(tileSetSource.texture_region_size)
					
					# erase from tilemap
					tile.set_cell(getTiles[i][1])
					getTiles.remove_at(i)
					# decrease i so we don't skip any tiles
					i -= 1

# check for players
func _on_body_entered(body):
	if !players.has(body):
		players.append(body)

func _on_body_exited(body):
	players.erase(body)
