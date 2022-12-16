extends TileMap
tool

# if to generate
export var scanTilemap = false

export var tiles = {}
export (NodePath)var sourceTiles

export var placeTiles = false

func _process(delta):
	# check if in editor
	if Engine.is_editor_hint():
		# check if generate is true
		if scanTilemap:
			scanTilemap = false
			# check that tileset check has been set
			var getTileset = get_node_or_null(sourceTiles)
			if getTileset != null:
				#cell_size/$"../TileMap".cell_size
				for i in getTileset.get_used_cells():
					# calculate size differences between the tileset and the chunks
					var difference = cell_size/getTileset.cell_size
					var tileOffset = i/difference
					
					# get source tile offset (position between chunks)
					var sourceTileOffset = Vector2(i-tileOffset.floor()*difference)
					
					var tileData = [sourceTileOffset,getTileset.get_cell_autotile_coord(i.x,i.y),getTileset.is_cell_x_flipped(i.x,i.y),getTileset.is_cell_y_flipped(i.x,i.y),getTileset.is_cell_transposed(i.x,i.y)]
					
					
					if tiles.has((tileOffset).floor()):
						tiles[(tileOffset).floor()].append(tileData)
					else:
						tiles[(tileOffset).floor()] = [tileData]
		
		if placeTiles:
			placeTiles = false
			$"../Destination".clear()
			for i in get_used_cells():
				var getID = get_cell_autotile_coord(i.x,i.y)
				for j in tiles[getID]:
					
					var getPose = (i*8)+j[0]
					$"../Destination".set_cell(getPose.x,getPose.y,0,j[2],j[3],j[4],j[1])
