extends TileMap

export (PoolIntArray) var tiles;

export(String, FILE, "*.json") var metaTileFile;
export(String, FILE, "*.json") var tilesetFile;

var metaTiles = {
#	# 0 = empty
#	0: {"Angle": 0, "HeightMap": [0,0,0,0,0,0,0,0]},
#	# 1 = filled
#	1: {"Angle": 0, "HeightMap": [8,8,8,8,8,8,8,8]},
};
var tile = {
	#0:
	# 0 empty tile
#	{
#		"TileData": [0,0,0,0],
#		"Dir": [[0,0],[0,0],[0,0],[0,0]]
#		"AnglePriority": [null,null,null,null]
#	},
};

var tileMap = {
#	0:[0,0,0],1:[0,0,0]]
}

var tileRegion = tile_set.tile_get_region(0).size/tile_set.autotile_get_size(0);
var tileSize = tile_set.autotile_get_size(0);

func _ready():
	if (metaTileFile):
		var file = File.new();
		file.open(metaTileFile, File.READ);
		metaTiles = JSON.parse(file.get_var()).result;
		file.close();
	if (tilesetFile):
		var file = File.new();
		file.open(tilesetFile, File.READ);
		var data = JSON.parse(file.get_var()).result;
		tile = data["Tile"];
		tileMap = data["TileMap"];
		file.close();

	#var getCell = get_cell_autotile_coord(-104/16,1160/16);
	#print(convertToTileID(getCell));
	#print(tileMap[str(convertToTileID(getCell))]);
	#print(metaTiles[ str(tile[str(tileMap[str(convertToTileID(getCell))][0])]["TileData"][3]) ]);
	var testPose = Vector2(320,1384+5);
	print(get_tile(testPose));
	print(get_tile_section(testPose));
	print(get_meta_tile(testPose));
	print(get_height(testPose));
	print(collision_check(testPose));


func get_tile_section(pose = Vector2.ZERO):
	var flip = get_flip(pose);
	pose = Vector2(fposmod(pose.x,tileSize.x),fposmod(pose.y,tileSize.y));
	if (flip.x):
		pose.x = tileSize.x-pose.x-1;
	if (flip.y):
		pose.y = tileSize.y-pose.y-1;
	return round(pose.x/tileSize.x)+round(pose.y/tileSize.y)*2

func convert_to_tile_ID(cellVector = Vector2.ZERO):
	return cellVector.x+(cellVector.y*tileRegion.x);

func get_tile(pose = Vector2.ZERO):
	pose = pose/16;
	var getID = (convert_to_tile_ID(get_cell_autotile_coord(pose.x,pose.y)));
	if (getID != -1):
		return tile[str(tileMap[str(getID)][0])];
	else:
		return null;

func get_meta_tile(pose = Vector2.ZERO):
	return metaTiles[str(get_tile(pose)["TileData"][get_tile_section(pose)])];

func get_height(pose = Vector2.ZERO):
	var heightMap = get_meta_tile(pose)["HeightMap"];
	var flip = get_flip(pose);
	pose.x = fposmod(pose.x,8);
	if (flip.x):
		pose.x = 7-pose.x;
	return heightMap[floor(pose.x)];

func get_angle(pose = Vector2.ZERO):
	var flip = get_flip(pose);
	if (!flip.x):
		return get_meta_tile(pose)["Angle"];
	else:
		return -get_meta_tile(pose)["Angle"];

func collision_check(pose = Vector2.ZERO):
	var flip = get_flip(pose);
	var getH = get_height(pose);
	var getPosY = fposmod(pose.y,8);
	if (flip.y):
		return (getPosY < getH);
	else:
		return (getPosY >= 8-getH);

func get_surface_point(origin = Vector2.ZERO, maxDistance = 8):
	var distance = 0;
	# Tile Check
	while (get_height(origin+Vector2.DOWN*distance) == 0 && abs(distance) < abs(maxDistance)):
		distance = min(abs(distance)+8,abs(maxDistance))*sign(maxDistance);
	
	if (distance >= maxDistance):
		return null;
	
	# Check by height
	
	var getPosY = stepify(distance-4,8);
	var flip = get_flip(origin+Vector2.DOWN*distance);
	if (flip.y):
		distance = getPosY-1;#getPosY+get_height(origin+Vector2.DOWN*distance);
	else:
		while (get_height(origin+Vector2.DOWN*distance) == 8):
			distance -= 8;
			getPosY -= 8;
		distance = getPosY+8-get_height(origin+Vector2.DOWN*distance);

	return origin+Vector2.DOWN*distance;
	
	

func get_flip(pose = Vector2.ZERO):
	return Vector2(is_cell_x_flipped(pose.x/tileSize.x,pose.y/tileSize.y),is_cell_y_flipped(pose.x/tileSize.x,pose.y/tileSize.y));

#var metaTiles = {
##	# 0 = empty
##	0: {"Angle": 0, "HeightMap": [0,0,0,0,0,0,0,0]},
##	# 1 = filled
##	1: {"Angle": 0, "HeightMap": [8,8,8,8,8,8,8,8]},
#};
#var tile = {
#	#0:
#	# 0 empty tile
##	{
##		"TileData": [0,0,0,0],
##		"Dir": [[0,0],[0,0],[0,0],[0,0]]
##		"AnglePriority": [null,null,null,null]
##	},
#};
#
#var tileMap = {
##	0:[0,0,0],1:[0,0,0]]
#}
