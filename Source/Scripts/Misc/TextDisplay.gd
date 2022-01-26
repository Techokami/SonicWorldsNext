extends Sprite2D

var stringLookup = {
'A': 0,
'B': 1,
'C': 2,
'D': 3,
'E': 4,
'F': 5,
'G': 6,
'H': 7,
'I': 8,
'J': 9,
'K': 10,
'L': 11,
'M': 12,
'N': 13,
'O': 14,
'P': 15,
'Q': 16,
'R': 17,
'S': 18,
'T': 19,
'U': 20,
'V': 21,
'W': 22,
'X': 23,
'Y': 24,
'Z': 25,
};
var smallStringLookup = {
'0': 0,
'1': 1,
'2': 2,
'3': 3,
'4': 4,
'5': 5,
'6': 6,
'7': 7,
'8': 8,
'9': 9,
'a': 10,
'b': 11,
'c': 12,
'd': 13,
'e': 14,
'f': 15,
'g': 16,
'h': 17,
'i': 18,
'j': 19,
'k': 20,
'l': 21,
'm': 22,
'n': 23,
'o': 24,
'p': 25,
'q': 26,
'r': 27,
's': 28,
't': 29,
'u': 30,
'v': 31,
'w': 32,
'x': 33,
'y': 34,
'z': 35,
};

@export var string = "123XYZ";
@onready var stringMem = string;

@export var smallStringTexture = preload("res://Graphics/HUD/LevelCards/font/smallfont3.png")
@export var hasNumbers = false
@export var smallHasNumber = true

@export var smallHframes = 10
@export var smallVframes = 4

@export_enum("Top", "Middle", "Bottom") var align = 0

func _ready():
	region_enabled = true;

func _process(delta):
	if (stringMem != string):
		stringMem = string;
		update();


func _draw():
	var getRes = Vector2(texture.get_width()/hframes,texture.get_height()/vframes);
	var getX = 0
	var vAlign = ((texture.get_height()/vframes)-(smallStringTexture.get_height()/smallVframes))*(align/2)
	for i in string.length():
		if (stringLookup.has(string[i]) || smallStringLookup.has(string[i])):
			var charID = 0;
			var gethFrames = hframes
			var getvFrames = vframes
			var getTexture = texture
			var yOff = 0
			if (smallStringLookup.has(string[i])):
				gethFrames = smallHframes
				getvFrames = smallVframes
				charID = smallStringLookup[string[i]]
				getTexture = smallStringTexture
				yOff = vAlign
			else:
				charID = stringLookup[string[i]]
			
			getRes = Vector2(getTexture.get_width()/gethFrames,getTexture.get_height()/getvFrames);
				
			draw_texture_rect_region(getTexture,
			Rect2(Vector2(getX,yOff),getRes),
			Rect2(Vector2(fmod(charID,gethFrames)*getRes.x,floor(charID/gethFrames)*getRes.y),getRes));
		getX += getRes.x
