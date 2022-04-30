extends Node2D

@export var music = preload("res://Audio/Soundtrack/6. SWD_TLZa1.ogg")
@export var levelTopName = "Green"
@export var levelBottomName = "Hill"
@export var act = 1
@export var showCard = true

var TitleCard = preload("res://entities/main/title_card.tscn")

func _ready():
	if Global.main != null:
		# set main music stream to the music file
		Global.main.music.stream = music
		# restart the music player
		Global.main.music.play()

	# Title card
	if showCard:
		var card = TitleCard.instantiate()
		card.get_node("Control/TopName").string = levelTopName
		card.get_node("Control/TopName/BottomName").string = levelBottomName
		add_child(card)
		get_tree().paused = true
		await card.get_node("TitleCardAnimator").animation_finished
		get_tree().paused = false
		card.get_node("TitleCardAnimator").play("TileCardEnd")
		
