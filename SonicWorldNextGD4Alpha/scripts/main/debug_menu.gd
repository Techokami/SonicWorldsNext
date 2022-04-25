extends Node2D

@export var music = preload("res://Audio/Soundtrack/10. SWD_CharacterSelect.ogg")
var rooms = [preload("res://scenes/TileMap.tscn"),preload("res://scenes/TileMap.tscn"),preload("res://scenes/GreenHillAct1.tscn")]
var roomEnd = false

var levelNames = [
"TileMap Test",
"Test Zone",
"Green hill Zone Act 1",
"                    2",
"                    3",
]
var option = 0
@onready var getOption = $Option

func _ready():
	Global.main.music.stream = music
	Global.main.music.play()
	
	for i in levelNames:
		getOption.string = i
		var newOp = getOption.duplicate()
		add_child(newOp)
		getOption.position.y += 8
	
	
	getOption.string = '*'

func _process(delta):
	getOption.position = Vector2(8,4+(8*(option+1)))


func _input(event):
	if event.is_action_pressed("gm_pause") && !roomEnd:
		roomEnd = true
		Global.main.switchScene(rooms[option],"FadeBlack","FadeBlack")
	if event.is_action_pressed("gm_down"):
		option = wrapi(option+1,0,rooms.size())
	if event.is_action_pressed("gm_up"):
		option = wrapi(option-1,0,rooms.size())
