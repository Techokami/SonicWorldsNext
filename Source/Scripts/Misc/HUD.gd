extends CanvasLayer

export var focusPlayer = 0

onready var scoreText = $Counters/Text/ScoreNumber
onready var timeText = $Counters/Text/TimeNumbers
onready var ringText = $Counters/Text/RingCount

onready var lifeText = $LifeCounter/Icon/LifeText

export var playLevelCard = true
export var zoneName = "Base"
export var zone = "Zone"
export var act = 1

var flashTimer = 0

var endingPhase = 0
var timeBonus = 0
var ringBonus = 0

var gameOver = false

signal tally_clear

var characterNames = ["sonic","tails","knuckles"]

func _ready():
	Global.hud = self
	# Set character Icon
	$LifeCounter/Icon.frame = Global.PlayerChar1-1
	
	if (playLevelCard):
		$LevelCard.visible = true
		$LevelCard/Banner/LevelName.string = zoneName
		$LevelCard/Banner/Zone.string = zone
		$LevelCard/Banner/Act.frame = act-1
		$LevelCard/Banner/Act.visible = (act > 0)
		get_tree().paused = true
		$LevelCard/CardPlayer.play("Start")
		$LevelCard/CardMover.play("Slider")
		yield($LevelCard/CardPlayer,"animation_finished")
		$LevelCard/CardPlayer.play("End")
		get_tree().paused = false
		Global.emit_signal("stage_started")
		yield($LevelCard/CardPlayer,"animation_finished")
	else:
		Global.emit_signal("stage_started")
	$LevelCard.queue_free()
	
	$LevelClear/Passed.string = $LevelClear/Passed.string.replace("sonic",characterNames[Global.PlayerChar1-1])

func _process(delta):
	scoreText.string = "%6d" % Global.score
	var timeClamp = min(Global.levelTime,Global.maxTime-1)
	timeText.string = "%2d" % floor(timeClamp/60) + ":" + str(fmod(floor(timeClamp),60)).pad_zeros(2)
	if (Global.players.size() > 0):
		ringText.string = "%3d" % Global.players[focusPlayer].rings
	
	
	lifeText.string = "%2d" % Global.lives
	
	# Water Overlay
	if Global.waterLevel != null:
		var cam = GlobalFunctions.getCurrentCamera2D()
		if cam != null:
			$Water/WaterOverlay.rect_position.y = clamp(Global.waterLevel-GlobalFunctions.getCurrentCamera2D().get_camera_screen_center().y+(get_viewport().get_visible_rect().size.y/2),0,get_viewport().get_visible_rect().size.y)
		$Water/WaterOverlay.rect_scale.y = clamp(Global.waterLevel-$Water/WaterOverlay.rect_position.y,0,get_viewport().size.y)
		$Water/WaterOverlay.visible = true
		#$Water/WaterOverlay/TextureRect.rect_position.y = Global.waterLevel-GlobalFunctions.getCurrentCamera2D().global_position.y-$Water/WaterOverlay/TextureRect.rect_position.y
	else:
		$Water/WaterOverlay.visible = false
	
	if flashTimer < 0:
		flashTimer = 0.1
		if Global.players[focusPlayer].rings <= 0:
			$Counters/Text/Rings.visible = !$Counters/Text/Rings.visible
		else:
			$Counters/Text/Rings.visible = false
		if Global.levelTime >= 60*9:
			$Counters/Text/Time.visible = !$Counters/Text/Time.visible
		else:
			$Counters/Text/Time.visible = false
	else:
		flashTimer -= delta
	
	if Global.stageClearPhase > 2:
		if endingPhase == 0:
			endingPhase = 1
			$LevelClear.visible = true
			$LevelClear/Tally/ScoreNumber.string = scoreText.string
			$LevelClear/Animator.play("LevelClear")
			ringBonus = floor(Global.players[focusPlayer].rings)*100
			$LevelClear/Tally/RingNumbers.string = "%6d" % ringBonus
			timeBonus = 0
			var bonusTable = [
			[60*5,500],
			[60*4,1000],
			[60*3,2000],
			[60*2,3000],
			[60*1.5,4000],
			[60,5000],
			[45,10000],
			[30,50000],
			]
			
			for i in bonusTable:
				if Global.levelTime < i[0]:
					timeBonus = i[1]
			$LevelClear/Tally/TimeNumbers.string = "%6d" % timeBonus
			$LevelClear/CounterWait.start()
			yield($LevelClear/CounterWait,"timeout")
			$LevelClear/CounterCount.start()
			yield(self,"tally_clear")
			$LevelClear/CounterWait.start(2)
			yield($LevelClear/CounterWait,"timeout")
			Global.main.change_scene(Global.nextZone,"FadeOut","FadeOut","SetSub",1)
	elif Global.gameOver && !gameOver:
		gameOver = true
		if Global.levelTime >= Global.maxTime:
			$GameOver/Game.frame = 1
		$GameOver/GameOver.play("GameOver")
		$GameOver/GameOverMusic.play()
		Global.music.stop()
		Global.effectTheme.stop()
		Global.life.stop()
		yield($GameOver/GameOver,"animation_finished")
		# reset game
		if Global.levelTime < Global.maxTime || Global.lives <= 0:
			Global.main.change_scene(Global.startScene,"FadeOut")
			yield(Global.main,"scene_faded")
			Global.reset_values()
		else:
			Global.main.change_scene(null,"FadeOut")
			yield(Global.main,"scene_faded")
			Global.levelTime = 0


func _on_CounterCount_timeout():
	$LevelClear/Counter.play()
	
	if timeBonus > 0:
		timeBonus -= 100
		Global.score += 100
	elif ringBonus > 0:
		ringBonus -= 100
		Global.score += 100
	else:
		$LevelClear/Counter.play()
		$LevelClear/CounterCount.stop()
		$LevelClear/Score.play()
		emit_signal("tally_clear")
	$LevelClear/Tally/ScoreNumber.string = scoreText.string
	$LevelClear/Tally/TimeNumbers.string = "%6d" % timeBonus
	$LevelClear/Tally/RingNumbers.string = "%6d" % ringBonus
	
