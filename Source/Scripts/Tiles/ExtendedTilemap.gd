extends TileMap

export (PoolIntArray) var tiles;

var metaTiles = {};

#func _ready():
#	metaTiles = {"ID0": {"HeightMap": [8,7,6,5,4,3,2,1], "Angle": 45, "XDir": 1, "YDir": 1,},
#				 "ID1": {"HeightMap": [8,8,8,8,8,8,8,8], "Angle": 0, "XDir": 1, "YDir": 1},};
#
#	var file = File.new();
#	file.open("res://Test.json", File.READ);
#	var metaGetTile = file.get_var();
#	file.close();
#
#	file = File.new();
#	file.open("res://Test.json", File.WRITE);
#	file.store_var(to_json(metaTiles));
#	file.close();
