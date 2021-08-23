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
		
	#print(get_cell_autotile_coord(-16,1296))
	var test = (Vector2(-72-1,1256-1));
	var getID = (convert_to_tile_ID(get_cell_autotile_coord(test.x,test.y)));
	print(get_height(test));
	print(get_tile(test));
	print(get_meta_tile(test));
	#var getCell = get_cell_autotile_coord(-104/16,1160/16);
	#print(convertToTileID(getCell));
	#print(tileMap[str(convertToTileID(getCell))]);
	#print(metaTiles[ str(tile[str(tileMap[str(convertToTileID(getCell))][0])]["TileData"][3]) ]);
#	var testPose = Vector2(287+8,1523);
#	print("tile: ",get_tile(testPose));
#	print("tile section: ",get_tile_section(testPose));
#	print("Meta: ",get_meta_tile(testPose));
#	print("Height: ",get_height(testPose));
#	print("Collision: ",collision_check(testPose))
#
#	print("Angle: ",rad2deg(get_angle(testPose)));
#	print("Width: ",get_width(testPose));
#	print("Flip: ",get_flip(testPose));
#	print("Flip inc meta: ",get_flip(testPose,true));


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
	pose = pose_converter(pose)/16;
	var getID = (convert_to_tile_ID(get_cell_autotile_coord(pose.x,pose.y)));
	if (getID != -1):
		return tile[str(tileMap[str(getID)][0])];
	else:
		return null;

func get_meta_tile(pose = Vector2.ZERO):
	return metaTiles[str(get_tile(pose)["TileData"][get_tile_section(pose)])];

func get_height(pose = Vector2.ZERO):
	var heightMap = get_meta_tile(pose)["HeightMap"];
	var flip = get_flip(pose,false);
	var offset = fposmod(pose.x,8);
	if (flip.x):
		offset = 7-offset;
	return heightMap[floor(offset)];
	
func get_width(pose = Vector2.ZERO):
	var heightMap = get_meta_tile(pose)["HeightMap"];
	var flip = get_flip(pose,true);
	pose.y = fposmod(pose.y,8);
	if (!flip.y):
		pose.y = 8-pose.y;
	# calculate the width
	var width = 0;
	for i in range(heightMap.size()):
		if (pose.y < heightMap[i]):
			width += 1;
	return width;

func get_angle(pose = Vector2.ZERO, var defaultAngle = Vector2.UP):
	var flip = get_flip(pose,false);
	if (get_tile(pose)["Angle"] == deg2rad(0)):
		return defaultAngle.rotated(deg2rad(90)).angle();
	if (!flip.y):
		if (!flip.x):
			#	print("Default");
			#else:
			return abs(get_tile(pose)["Angle"]);
		else:
			return -abs(get_tile(pose)["Angle"]);
	else:
		if (!flip.x):
			#if (get_meta_tile(pose)["Angle"] == deg2rad(0)):
				#return defaultAngle.rotated(deg2rad(90)).angle();
			#	print("Default");
			#else:
			return deg2rad(180)-abs(get_tile(pose)["Angle"]);
		else:
			return deg2rad(180)+abs(get_tile(pose)["Angle"]);

func get_meta_angle(pose = Vector2.ZERO, var defaultAngle = Vector2.UP):
	var flip = get_flip(pose,true);
	if (get_meta_tile(pose)["Angle"] == deg2rad(0)):
		return defaultAngle.rotated(deg2rad(90)).angle();
	if (!flip.y):
		if (!flip.x):
			#	print("Default");
			#else:
			return abs(get_meta_tile(pose)["Angle"]);
		else:
			return -abs(get_meta_tile(pose)["Angle"]);
	else:
		if (!flip.x):
			#if (get_meta_tile(pose)["Angle"] == deg2rad(0)):
				#return defaultAngle.rotated(deg2rad(90)).angle();
			#	print("Default");
			#else:
			return deg2rad(180)-abs(get_meta_tile(pose)["Angle"]);
		else:
			return deg2rad(180)+abs(get_meta_tile(pose)["Angle"]);

func collision_check(pose = Vector2.ZERO):
	var flip = get_flip(pose,true);
	var getH = get_height(pose);
	var getPosY = fposmod(pose.y,8);
	if (flip.y):
		return (getPosY < getH);
	else:
		return (getPosY >= 8-getH);

func get_surface_point(origin = Vector2.ZERO, maxDistance = 8, horizontal = false):
	var distance = 0;
	# Tile Check
	if (!horizontal):
		while (get_height(origin+Vector2.DOWN*distance) == 0 && abs(distance) < abs(maxDistance)):
			distance = min(abs(distance)+8,abs(maxDistance))*sign(maxDistance);
	else:
		while (get_width(origin+Vector2.RIGHT*distance) == 0 && abs(distance) < abs(maxDistance)):
			distance = min(abs(distance)+8,abs(maxDistance))*sign(maxDistance);
	
	if (distance*sign(maxDistance) >= abs(maxDistance)):
		return null;
	
	# Check by height
	var getPos = stepify(distance-4,8);
	
	if (!horizontal):
		var flip = get_flip(origin+Vector2.DOWN*distance,true);
		if (sign(maxDistance) >= 0):
			if (flip.y):
				distance = getPos-1;
			else:
				while (get_height(origin+Vector2.DOWN*distance) == 8):
					distance -= 8;
					getPos -= 8;
				distance = getPos+8-get_height(origin+Vector2.DOWN*distance);
		else:
			if (!flip.y):
				distance = getPos+8;
			else:
				while (get_height(origin+Vector2.DOWN*distance) == 8):
					distance += 8;
					getPos += 8;
				distance = getPos+get_height(origin+Vector2.DOWN*distance);
	else:
		var flip = get_flip(origin+Vector2.RIGHT*distance,true);
		if (sign(maxDistance) >= 0):
			if (!flip.x):
				distance = getPos-1;
			else:
				while (get_width(origin+Vector2.RIGHT*distance) == 8):
					distance -= 8;
					getPos -= 8;
				distance = getPos+8-get_width(origin+Vector2.RIGHT*distance);
		else:
			if (flip.x):
				distance = getPos+8;
			else:
				while (get_width(origin+Vector2.RIGHT*distance) == 8):
					distance += 8;
					getPos += 8;
				distance = getPos+get_width(origin+Vector2.RIGHT*distance);

	if (!horizontal):
		return origin+Vector2.DOWN*distance;
	else:
		return origin+Vector2.RIGHT*distance;
	
	

func get_flip(pose = Vector2.ZERO, includeMeta = false):
	pose = pose_converter(pose);
	if (!includeMeta):
		return Vector2(is_cell_x_flipped(pose.x/tileSize.x,pose.y/tileSize.y),is_cell_y_flipped(pose.x/tileSize.x,pose.y/tileSize.y));
	else:
		#print(sign(get_meta_tile(pose)["Angle"]))
#		print(get_tile(pose)["Dir"][get_tile_section(pose)][0]);
		return Vector2(
		is_cell_x_flipped(pose.x/tileSize.x,pose.y/tileSize.y) != (get_tile(pose)["Dir"][get_tile_section(pose)][0] || get_meta_tile(pose)["Angle"] < 0),
		int(is_cell_y_flipped(pose.x/tileSize.x,pose.y/tileSize.y)) != get_tile(pose)["Dir"][get_tile_section(pose)][1]);

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

func pose_converter(pose = Vector2.ZERO):
	if (pose.x < 0):
		pose.x -= 15;
	if (pose.y < 0):
		pose.y -= 15;
	return pose;
