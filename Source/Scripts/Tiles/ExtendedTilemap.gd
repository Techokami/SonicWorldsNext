extends TileMap

export (PoolIntArray) var tiles;

var tileMap = [];
var tile = [
	{
		"TileData": [0,4,0,1],
	},
	{
		"TileData": [2,0,3,2],
		"Dir:": [[1,0],[0,0],[0,1],[0,1]],
		"AnglePriority": [45,45,null,null],
	},
]

func _ready():
	for i in range(32):
		tileMap.append([]);
		for j in range(32):
			tileMap[i].append(0);
	tileMap[13][14] = 1;
	var get_cell = get_cell_autotile_coord(-104/16,1160/16);
	print(tile[tileMap[get_cell.x][get_cell.y]]["AnglePriority"][0]);

#func _ready():
#	var tileTable = {"TileData": [[0,0,1,0],[1,0,2,1]], "TileMap": [0,1,2]};
##	metaTiles = {"ID0": {"HeightMap": [8,7,6,5,4,3,2,1], "Angle": 45, "XDir": 1, "YDir": 1,},
##				 "ID1": {"HeightMap": [8,8,8,8,8,8,8,8], "Angle": 0, "XDir": 1, "YDir": 1},};
##
##	var file = File.new();
##	file.open("res://Test.json", File.READ);
##	var metaGetTile = file.get_var();
##	file.close();
##
#	var file = File.new();
#	file.open("res://Test2.json", File.WRITE);
##	file.store_var(to_json(metaTiles));
#	file.store_var(to_json(tileTable));
#	file.close();
