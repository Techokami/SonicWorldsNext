extends TileMap
tool

# if to generate
export var scanTilemap = false

# tile dictionary
export var tiles = {}
export (NodePath)var sourceTiles

export var placeTiles = false

func _process(delta):
	# check if in editor
	if Engine.is_editor_hint():
		# Update source tile dictionary
		
		# check if generate is true
		if scanTilemap:
			scanTilemap = false
			
			# check that the source tile node has been set
			var getTileset = get_node_or_null(sourceTiles)
			if getTileset != null:
				# loop through the used tiles
				for i in getTileset.get_used_cells():
					
					# calculate size differences between the tileset and the chunks
					var difference = cell_size/getTileset.cell_size
					var tileOffset = i/difference
					
					# get source tile offset (position between chunks)
					var sourceTileOffset = Vector2(i-tileOffset.floor()*difference)
					
					# add the tile to the dictionary using the cell coordinates as the key
					var tileData = [sourceTileOffset,getTileset.get_cell_autotile_coord(i.x,i.y),getTileset.is_cell_x_flipped(i.x,i.y),getTileset.is_cell_y_flipped(i.x,i.y),getTileset.is_cell_transposed(i.x,i.y)]
					
					# check that the current chunk of tiles exists in the dictionary
					if tiles.has((tileOffset).floor()):
						tiles[(tileOffset).floor()].append(tileData)
					# if a chunk for the current tile position doesn't exist in the chunks, then create a new one
					else:
						tiles[(tileOffset).floor()] = [tileData]
		
		if placeTiles:
			placeTiles = false
			# clear tiles out
			var destination = $"../Destination"
			destination.clear()
			var gridSize = (cell_size/destination.cell_size)
			
			# loop through cells of the chunks
			for i in get_used_cells():
				# get chunk ID (used as reference for the tiles dictionary)
				var getID = get_cell_autotile_coord(i.x,i.y)
				var getFlipsVec = Vector2(1-int(is_cell_x_flipped(i.x,i.y))*2,1-int(is_cell_y_flipped(i.x,i.y))*2)
				for j in tiles[getID]:
					
					var getPose = (j[0]-gridSize/2)
					
					if is_cell_transposed(i.x,i.y):
						getPose = getPose.rotated(deg2rad(-90))*Vector2(1,-1)
					
					getPose = getPose*getFlipsVec-Vector2(int(getFlipsVec.x <= 0),int(getFlipsVec.y <= 0))
					
					getPose += gridSize/2
					
					getPose = (i*8)+getPose
					
					$"../Destination".set_cell(getPose.x,getPose.y,0,
					(j[2] != is_cell_x_flipped(i.x,i.y)),
					(j[3] != is_cell_y_flipped(i.x,i.y)),
					(j[4] != is_cell_transposed(i.x,i.y)),
					j[1])
