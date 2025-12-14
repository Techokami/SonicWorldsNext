extends Sprite2D
# string look up, put a character in here and the frame index for the texture it represents
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

@export var string = "03"
@onready var stringMem = string

func _ready():
	region_enabled = true

func _process(_delta):
	if (stringMem != string):
		stringMem = string
		queue_redraw()


func _draw():
	# calculate the resolution of the sprite text
	var getRes = Vector2(texture.get_width()/float(hframes),texture.get_height()/float(vframes))
	for i in string.length():
		var charID: int = stringLookup[string[i]]
		if charID != -1:
			draw_texture_rect_region(texture,
				Rect2(Vector2(getRes.x*i,0),getRes),
				Rect2(Vector2(fmod(charID,hframes),floor(charID/hframes))*getRes,getRes))
