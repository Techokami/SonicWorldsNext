extends Sprite

var stringLookup = {
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
':': 10,
}

export var string = "03"
onready var stringMem = string

func _ready():
	region_enabled = true

func _process(_delta):
	if (stringMem != string):
		stringMem = string
		update()


func _draw():
	var getRes = Vector2(texture.get_width()/float(hframes),texture.get_height()/float(vframes))
	for i in string.length():
		if (stringLookup.has(string[i])):
			var charID = stringLookup[string[i]]
			draw_texture_rect_region(texture,
			Rect2(Vector2(getRes.x*i,0),getRes),
			Rect2(Vector2(fmod(charID,hframes)*getRes.x,floor(charID/hframes)*getRes.y),getRes))
