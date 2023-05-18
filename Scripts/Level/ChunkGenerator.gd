#@tool
extends TileMap
#
#
## if to generate
#@export var scanTilemap = false
#
## tile dictionary
## key is the position, divided by the chunkmap cell size
## the tiles pull from any tilemaps under a source tiles layer (this gets deleted when the game runs)
## the tiles are made of an array, the order starts the tile layer ID, the offset coordinantes, the autotile / atlas coord, the x flip, the y flip, and the transpose
#@export var tiles = {}
#@export_node_path var sourceTiles
#@export_node_path var destinationTileMaps
#
#@export var placeTiles = false
#
#
#func _process(delta):
#	# check if in editor
#	if Engine.is_editor_hint():
#		# Update source tile dictionary
#
#		# check if generate is true
#		if scanTilemap:
#			scanTilemap = false
#
#			# check that the source tile node has been set
#			var getSource = get_node_or_null(sourceTiles)
#			if getSource != null:
#				tiles = {}
#				# loop through the used tiles and layers
#				for layerID in range(getSource.get_child_count()):
#					var getTileset = getSource.get_child(layerID)
#					for i in getTileset.get_used_cells():
#
#						# calculate size differences between the tileset and the chunks
#						var difference = cell_quadrant_size/getTileset.cell_quadrant_size
#						var tileOffset = i/difference
#
#						# get source tile offset (position between chunks)
#						var sourceTileOffset = Vector2(i-tileOffset.floor()*difference)
#
#						# add the tile to the dictionary using the cell coordinates as the key
#						var tileData = [layerID,sourceTileOffset,getTileset.get_cell_autotile_coord(i.x,i.y),getTileset.is_cell_x_flipped(i.x,i.y),getTileset.is_cell_y_flipped(i.x,i.y),getTileset.is_cell_transposed(i.x,i.y)]
#
#						# check that the current chunk of tiles exists in the dictionary
#						if tiles.has((tileOffset).floor()):
#							tiles[(tileOffset).floor()].append(tileData)
#						# if a chunk for the current tile position doesn't exist in the chunks, then create a new one
#						else:
#							tiles[(tileOffset).floor()] = [tileData]
#
#
#
#		if placeTiles:
#			placeTiles = false
#			# clear tiles out
#			var destination = get_node_or_null(destinationTileMaps)
#			var getSource = get_node_or_null(sourceTiles)
#			if destination != null:
#				var gridSize = (cell_quadrant_size/getSource.get_child(0).cell_quadrant_size)
#
#				for i in destination.get_children():
#					i.clear()
#
#				# loop through cells of the chunks
#				for i in get_used_cells(0):
#					# get chunk ID (used as reference for the tiles dictionary)
#					var getID = get_cell_atlas_coords(0,Vector2i(i.x,i.y))
#					var getFlipsVec = Vector2(1-int(is_cell_x_flipped(i.x,i.y))*2,1-int(is_cell_y_flipped(i.x,i.y))*2)
#					for j in tiles[getID]:
#						var getPose = (j[1]-gridSize/2)
#
#						if is_cell_transposed(i.x,i.y):
#							getPose = getPose.rotated(deg_to_rad(-90))*Vector2(1,-1)
#
#						# do some movement calculations, shifting back by half to rotate
#						getPose = getPose*getFlipsVec-Vector2(int(getFlipsVec.x <= 0),int(getFlipsVec.y <= 0))
#
#						getPose += gridSize/2
#
#						getPose = (i*8)+getPose
#
#						var getFlipArray = [j[3] != is_cell_x_flipped(i.x,i.y),j[4] != is_cell_y_flipped(i.x,i.y),j[5],is_cell_x_flipped(i.x,i.y),is_cell_y_flipped(i.x,i.y)]
#
#						# only calculate if cell is transposed
#						if is_cell_transposed(i.x,i.y):
#							getFlipArray = transposedDictionary.get([j[3],j[4],j[5],
#							is_cell_x_flipped(i.x,i.y),
#							is_cell_y_flipped(i.x,i.y)])
#
#						destination.get_child(j[0]).set_cell(getPose.x,getPose.y,0,
#						getFlipArray[0],getFlipArray[1],getFlipArray[2],
#						j[2])
#	else:
#		var getSource = get_node_or_null(sourceTiles)
#		if getSource != null:
#			getSource.queue_free()
#
#
#
## flip dictionary (used for referencing transposing)
## [tile flip x, tile flip y, tile transposed, cell flip x, cell flip y]
## secondary array is to set flip x, flip y, and to transpose
#var transposedDictionary = {
## cells not flipped
#[false, false, false, false, false]: [false, false, true],
## single true
#[true, false, false, false, false]: [false, true, true],
#[false, true, false, false, false]: [true, false, true],
#[false, false, true, false, false]: [false, false, false],# untested
## double true
#[true, true, false, false, false]: [true, true, true],
#[true, false, true, false, false]: [false, false, false],# untested
#[false, true, true, false, false]: [false, false, false],# untested
## all true
#[true, true, true, false, false]: [false, false, false],# untested
#
## cells x flipped
#[false, false, false, true, false]: [true, false, true],
## single true
#[true, false, false, true, false]: [true, true, true],
#[false, true, false, true, false]: [false, false, true],
#[false, false, true, true, false]: [false, false, false], # untested
## double true
#[true, true, false, true, false]: [false, true, true],
#[true, false, true, true, false]: [false, false, false], # untested
#[false, true, true, true, false]: [false, false, false], # untested
## all true
#[true, true, true, true, false]: [false, false, false], # untested
#
## cells y flipped
#[false, false, false, false, true]: [false, true, true],
## single true
#[true, false, false, false, true]: [false, false, true],
#[false, true, false, false, true]: [true, true, true],
#[false, false, true, false, true]: [false, false, false], # untested
## double true
#[true, true, false, false, true]: [true, false, true],
#[true, false, true, false, true]: [false, false, false], # untested
#[false, true, true, false, true]: [false, false, false], # untested
## all true
#[true, true, true, false, true]: [false, false, false], # untested
#
## cells all flipped
#[false, false, false, true, true]: [true, true, true],
## single true
#[true, false, false, true, true]: [true, false, true],
#[false, true, false, true, true]: [false, true, true],
#[false, false, true, true, true]: [false, false, false], # untested
## double true
#[true, true, false, true, true]: [false, false, true],
#[true, false, true, true, true]: [false, false, false], # untested
#[false, true, true, true, true]: [false, false, false], # untested
## all true
#[true, true, true, true, true]: [false, false, false], # untested
#}
