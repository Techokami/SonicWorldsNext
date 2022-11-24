extends TileMap
export (NodePath) var tileMapLink

onready var lowSolid = $LowSolid
onready var highSolid = $HighSolid
onready var background = $Background
onready var lowTop = $LowTop
onready var highTop = $HighTop
onready var top = $Top
# tile list corresponds with the look up varaibles based on the tile ID of any placed tiles
onready var tileList = [highSolid,lowSolid,background,highTop,lowTop,top]

var tileMap = null

func _ready():
	visible = false
	if (get_node_or_null(tileMapLink) is TileMap):
		
		tileMap = get_node(tileMapLink)
		# connect tilemaps
		for i in tileList:
			remove_child(i)
			tileMap.add_child(i)
			i.tile_set = tileMap.tile_set
			collision_mask = collision_layer
			i.z_index = tileMap.z_index
		
		# bring tiles into the corresponding layers based on the current painter tile
		for i in get_used_cells():
			var tileUV = get_cell_autotile_coord(i.x,i.y)
			var tilemapID = tileUV.x+(tileUV.y*3)
			
			var cellTileID = tileMap.get_cell(i.x,i.y)
			var cellAuto = tileMap.get_cell_autotile_coord(i.x,i.y)
			var cellTransposed = tileMap.is_cell_transposed(i.x,i.y)
			var flipX = tileMap.is_cell_x_flipped(i.x,i.y)
			var flipY = tileMap.is_cell_y_flipped(i.x,i.y)
			
			tileList[tilemapID].set_cell(i.x,i.y,cellTileID,flipX,flipY,cellTransposed,cellAuto)
			
			tileMap.set_cell(i.x,i.y,-1)
			set_cell(i.x,i.y,-1)
