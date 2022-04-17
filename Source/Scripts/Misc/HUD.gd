extends CanvasLayer

export var focusPlayer = 0;

onready var scoreText = $Counters/Text/ScoreNumber;
onready var timeText = $Counters/Text/TimeNumbers;
onready var ringText = $Counters/Text/RingCount;

onready var lifeText = $LifeCounter/Icon/LifeText;

export var playLevelCard = true
export var zoneName = "Base"
export var zone = "Zone"
export var act = 1

func _ready():
	if (playLevelCard):
		$LevelCard.visible = true
		$LevelCard/Banner/LevelName.string = zoneName
		$LevelCard/Banner/Zone.string = zone
		$LevelCard/Banner/Act.frame = act-1
		$LevelCard/Banner/Act.visible = (act > 0)
		pause_mode = PAUSE_MODE_PROCESS
		get_tree().paused = true
		$LevelCard/TitleCardPlayer.play("Start")
		$LevelCard/CardMover.play("Slider")
		yield($LevelCard/TitleCardPlayer,"animation_finished")
		$LevelCard/TitleCardPlayer.play("End")
		get_tree().paused = false
		yield($LevelCard/TitleCardPlayer,"animation_finished")
		pause_mode = PAUSE_MODE_INHERIT
	$LevelCard.queue_free()

func _process(delta):
	scoreText.string = "%6d" % Global.score;
	timeText.string = "%2d" % floor(Global.levelTime/60) + ":" + str(fmod(floor(Global.levelTime),60)).pad_zeros(2);
	if (Global.players.size() > 0):
		ringText.string = "%3d" % Global.players[focusPlayer].rings;
	
	
	lifeText.string = "%2d" % Global.lives;
	
	# Water Overlay
	if Global.waterLevel != null:
		$Water/WaterOverlay.rect_position.y = clamp(Global.waterLevel-GlobalFunctions.getCurrentCamera2D().global_position.y+(get_viewport().get_visible_rect().size.y/2),0,get_viewport().get_visible_rect().size.y)
		$Water/WaterOverlay.rect_scale.y = clamp(Global.waterLevel-$Water/WaterOverlay.rect_position.y,0,get_viewport().size.y)
		#$Water/WaterOverlay/TextureRect.rect_position.y = Global.waterLevel-GlobalFunctions.getCurrentCamera2D().global_position.y-$Water/WaterOverlay/TextureRect.rect_position.y
	else:
		$Water/WaterOverlay.visible = false
