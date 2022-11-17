extends CanvasLayer

# player ID look up
export var focusPlayer = 0

# counter elements pointers
onready var scoreText = $Counters/Text/ScoreNumber
onready var timeText = $Counters/Text/TimeNumbers
onready var ringText = $Counters/Text/RingCount
onready var lifeText = $LifeCounter/Icon/LifeText

# play level card, if true will play the level card animator and use the zone name and zone text with the act
export var playLevelCard = true
export var zoneName = "Base"
export var zone = "Zone"
export var act = 1

# used for flashing ui elements (rings, time)
var flashTimer = 0

# isStageEnding is used for level completion, stop loop recursions
var isStageEnding = false

# level clear bonuses (check _on_CounterCount_timeout)
var timeBonus = 0
var ringBonus = 0

# gameOver is used to initialize the game over animation sequence, note: this is for animation, if you want to use the game over status it's in global
var gameOver = false

# signal that gets emited once the stage tally is over
signal tally_clear

# character name strings, used for "[player] has cleared", this matches the players character ID so you'll want to add the characters name in here matching the ID if you want more characters
# see Global.PlayerChar1
var characterNames = ["sonic","tails","knuckles"]

func _ready():
	# stop timer from counting during stage start up and set global hud to self
	Global.timerActive = false
	Global.hud = self
	# Set character Icon
	$LifeCounter/Icon.frame = Global.PlayerChar1-1
	
	# play level card routine if level card is true
	if (playLevelCard):
		# set level card
		$LevelCard.visible = true
		# set level name strings
		$LevelCard/Banner/LevelName.string = zoneName
		$LevelCard/Banner/Zone.string = zone
		# set act graphic
		$LevelCard/Banner/Act.frame = act-1
		# make visible if act isn't 0 (0 will just be zone)
		$LevelCard/Banner/Act.visible = (act > 0)
		# make sure level card isn't paused so it can keep playing
		$LevelCard/CardPlayer.pause_mode = PAUSE_MODE_PROCESS
		# temporarily let music play during pauses
		Global.musicParent.pause_mode = PAUSE_MODE_PROCESS
		# pause game while card is playing
		get_tree().paused = true
		# play card animations
		$LevelCard/CardPlayer.play("Start")
		$LevelCard/CardMover.play("Slider")
		# wait for card to finish it's entrance animation, then play the end
		yield($LevelCard/CardPlayer,"animation_finished")
		$LevelCard/CardPlayer.play("End")
		# unpause the game and set previous pause mode nodes to stop on pause
		get_tree().paused = false
		Global.musicParent.pause_mode = PAUSE_MODE_STOP
		$LevelCard/CardPlayer.pause_mode = PAUSE_MODE_STOP
		# emit stage start signal
		Global.emit_stage_start()
		# wait for title card animator to finish ending before starting the level timer
		yield($LevelCard/CardPlayer,"animation_finished")
	else:
		# just emit the stage start signal and start the stage
		Global.emit_stage_start()
	Global.timerActive = true
	# replace "sonic" in stage clear to match the player clear string
	$LevelClear/Passed.string = $LevelClear/Passed.string.replace("sonic",characterNames[Global.PlayerChar1-1])

func _process(delta):
	# set score string to match global score with leading 0s
	scoreText.string = "%6d" % Global.score
	
	# clamp time so that it won't go to 10 minutes
	var timeClamp = min(Global.levelTime,Global.maxTime-1)
	# set time text, format it to have a leadin 0 so that it's always 2 digits
	timeText.string = "%2d" % floor(timeClamp/60) + ":" + str(fmod(floor(timeClamp),60)).pad_zeros(2)
	
	# cehck that there's player, if there is then track the focus players ring count
	if (Global.players.size() > 0):
		ringText.string = "%3d" % Global.players[focusPlayer].rings
	
	# track lives with leading 0s
	lifeText.string = "%2d" % Global.lives
	
	# Water Overlay
	
	# cehck that this level has water
	if Global.waterLevel != null:
		# get current camera
		var cam = GlobalFunctions.getCurrentCamera2D()
		if cam != null:
			# if camera exists place the water's y position based on the screen position as the water is a UI overlay
			$Water/WaterOverlay.rect_position.y = clamp(Global.waterLevel-GlobalFunctions.getCurrentCamera2D().get_camera_screen_center().y+(get_viewport().get_visible_rect().size.y/2),0,get_viewport().get_visible_rect().size.y)
		# scale water level to match the visible screen
		$Water/WaterOverlay.rect_scale.y = clamp(Global.waterLevel-$Water/WaterOverlay.rect_position.y,0,get_viewport().size.y)
		$Water/WaterOverlay.visible = true
		
		# Water Overlay Elec flash
		if (Global.players.size() > 0):
			# loop through players
			for i in Global.players:
				# check if in water and has elec or fire shield
				if i.water:
					match (i.shield):
						i.SHIELDS.ELEC:
							# reset shield do flash
							i.set_shield(i.SHIELDS.NONE)
							$Water/WaterOverlay/ElecFlash.visible = true
							# destroy all enemies in near player and below water
							for j in get_tree().get_nodes_in_group("Enemy"):
								if j.global_position.y >= Global.waterLevel and i.global_position.distance_to(j.global_position) <= 256:
									if j.has_method("destroy"):
										Global.add_score(j.global_position,Global.SCORE_COMBO[0])
										j.destroy()
							# disable flash after a frame
							yield(get_tree(),"idle_frame")
							$Water/WaterOverlay/ElecFlash.visible = false
						i.SHIELDS.FIRE:
							# clear shield
							i.set_shield(i.SHIELDS.NONE)
	else:
		# disable water overlay
		$Water/WaterOverlay.visible = false
	
	
	# HUD flashing text
	if flashTimer < 0:
		flashTimer = 0.1
		if Global.players.size() > 0:
			# if ring count at zero, flash rings
			if Global.players[focusPlayer].rings <= 0:
				$Counters/Text/Rings.visible = !$Counters/Text/Rings.visible
			else:
				$Counters/Text/Rings.visible = false
		# if minutes up to 9 then flash time
		if Global.levelTime >= 60*9:
			$Counters/Text/Time.visible = !$Counters/Text/Time.visible
		else:
			$Counters/Text/Time.visible = false
	elif !get_tree().paused:
		flashTimer -= delta
	
	# stage clear handling
	if Global.stageClearPhase > 2:
		# initialize stage clear sequence
		if !isStageEnding:
			isStageEnding = true
			
			# show level clear elements
			$LevelClear.visible = true
			$LevelClear/Tally/ScoreNumber.string = scoreText.string
			$LevelClear/Animator.play("LevelClear")
			
			# set bonuses
			ringBonus = floor(Global.players[focusPlayer].rings)*100
			$LevelClear/Tally/RingNumbers.string = "%6d" % ringBonus
			timeBonus = 0
			# bonus time table
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
			# loop through the bonus table, if current time is less then the first value then set it to that bonus
			# you'll want to make sure the order of the table goes down in time and up in score otherwise it could cause some weirdness
			for i in bonusTable:
				if Global.levelTime < i[0]:
					timeBonus = i[1]
			# set bonus text for time
			$LevelClear/Tally/TimeNumbers.string = "%6d" % timeBonus
			# wait for counter wait time to count down
			$LevelClear/CounterWait.start()
			yield($LevelClear/CounterWait,"timeout")
			# start the level counter tally (see _on_CounterCount_timeout)
			$LevelClear/CounterCount.start()
			yield(self,"tally_clear")
			# wait 2 seconds (reuse timer)
			$LevelClear/CounterWait.start(2)
			yield($LevelClear/CounterWait,"timeout")
			# after clear, change to next level in Global.nextZone (you can set the next zone in the level script node)
			Global.main.change_scene(Global.nextZone,"FadeOut","FadeOut","SetSub",1)
	
	# game over sequence
	elif Global.gameOver and !gameOver:
		# set game over to true so this doesn't loop
		gameOver = true
		# determine if the game over is a time over (game over and time over sequences are the same but game says time)
		if Global.levelTime >= Global.maxTime:
			$GameOver/Game.frame = 1
		# play game over animation and play music
		$GameOver/GameOver.play("GameOver")
		$GameOver/GameOverMusic.play()
		# stop normal music tracks
		Global.music.stop()
		Global.effectTheme.stop()
		Global.life.stop()
		# wait for animation to finish
		yield($GameOver/GameOver,"animation_finished")
		# reset game
		if Global.levelTime < Global.maxTime or Global.lives <= 0:
			Global.main.change_scene(Global.startScene,"FadeOut")
			yield(Global.main,"scene_faded")
			Global.reset_values()
		# reset level (if time over and lives aren't out)
		else:
			Global.main.change_scene(null,"FadeOut")
			yield(Global.main,"scene_faded")
			Global.levelTime = 0

# counter count down
func _on_CounterCount_timeout():
	# play counter sound
	$LevelClear/Counter.play()
	
	# decrease bonuses in order, if time bonus not 0 then count time down, then do the same for rings
	# if you add other bonuses (like perfect bonus) you'll want to add it to the end of the sequence before the end
	if timeBonus > 0:
		# check if adding score would hit the life bonus
		Global.check_score_life(100)
		timeBonus -= 100
		Global.score += 100
	elif ringBonus > 0:
		# check if adding score would hit the life bonus
		Global.check_score_life(100)
		ringBonus -= 100
		Global.score += 100
	else:
		# stop counter timer and play score sound
		$LevelClear/Counter.play()
		$LevelClear/CounterCount.stop()
		$LevelClear/Score.play()
		# emit tally clear signal
		emit_signal("tally_clear")
	# set the level clear strings to the bonuses
	$LevelClear/Tally/ScoreNumber.string = scoreText.string
	$LevelClear/Tally/TimeNumbers.string = "%6d" % timeBonus
	$LevelClear/Tally/RingNumbers.string = "%6d" % ringBonus
	
