@tool
extends CanvasLayer

static var tick_looped: AudioStreamWAV = null

# holds textures for each characters' icon and name text (not including Global.CHARACTERS.NONE)
static var lives_textures: Array[Texture2D] = []

# player ID look up
@export var focusPlayer = 0

# counter elements pointers
@onready var scoreText = $Counters/Text/ScoreNumber
@onready var timeText = $Counters/Text/TimeNumbers
@onready var ringText = $Counters/Text/RingCount
@onready var lifeText = $LifeCounter/Icon/LifeText

# play level card, if true will play the level card animator and use the zone name and zone text with the act
@export var playLevelCard = true
@export var zoneName = "Base"
@export var zone = "Zone"
@export var act = 1

# used for flashing UI elements (rings, time)
var flashTimer = 0

# isStageEnding is used for level completion, stop loop recursions
var isStageEnding = false

# level clear bonuses (check _on_CounterCount_timeout)
var timeBonus = 0
var ringBonus = 0

# gameOver is used to initialize the game over animation sequence, note: this is for animation, if you want to use the game over status it's in global
var gameOver = false

# used for the score countdown
var accumulatedDelta = 0.0

# signal that gets emited once the stage tally is over
signal tally_clear

func _ready():
	var in_editor: bool = Engine.is_editor_hint()
	if !in_editor:
		# create a new stream for the tick sound (so the original stream
		# will remain unchanged, as it's also used by the switch gimmick),
		# and set loop parameters, but don't enable looping yet
		if tick_looped == null:
			assert($LevelClear/Counter.stream is AudioStreamWAV)
			tick_looped = $LevelClear/Counter.stream.duplicate()
			tick_looped.loop_end = roundi(tick_looped.mix_rate / (60.0 / 4))
		$LevelClear/Counter.stream = tick_looped
	# load character icons
	# (if we are in the editor, only load the icon for the 1'st character
	# from the list, as the other icons won't be shown in the editor anyway)
	if lives_textures.is_empty():
		var char_names: Array = Global.CHARACTERS.keys()
		var num_characters: int = char_names.size()
		lives_textures.resize(1 if in_editor else num_characters)
		# replace "NONE" with the name of the 1'st character from the list,
		# for development purposes (e.g. when we implement a new game mode
		# and PlayerChar1 is not set, so Godot won't throw a ton of errors)
		char_names[0] = char_names[1]
		# load the icons
		for i: int in num_characters:
			lives_textures[i] = load("res://Graphics/HUD/hud_lives_%s.png" % char_names[i].to_lower()) as Texture2D
			if in_editor:
				$LifeCounter/Icon.texture = lives_textures[0]
				break
	if in_editor:
		set_process(false)
		return

	# error prevention
	if !Global.is_main_loaded:
		return
	
	# stop timer from counting during stage start up and set global hud to self
	Global.timerActive = false
	Global.hud = self
	# Set character Icon
	$LifeCounter/Icon.texture = lives_textures[Global.PlayerChar1]
	
	# play level card routine if level card is true
	if playLevelCard:
		# set level card
		$LevelCard.visible = true
		# set level name strings
		$LevelCard/Banner/LevelName.text = zoneName
		$LevelCard/Banner/Zone.text = zone
		# set act graphic
		$LevelCard/Banner/Act.frame = act-1
		# make visible if act isn't 0 (0 will just be zone)
		$LevelCard/Banner/Act.visible = (act > 0)
		# make sure level card isn't paused so it can keep playing
		$LevelCard/CardPlayer.process_mode = PROCESS_MODE_ALWAYS
		# temporarily let music play during pauses
		if Global.musicParent != null:
			Global.musicParent.process_mode = PROCESS_MODE_ALWAYS
		# pause game while card is playing
		get_tree().paused = true
		# play card animations
		$LevelCard/CardPlayer.play("Start")
		$LevelCard/CardMover.play("Slider")
		# wait for card to finish it's entrance animation, then play the end
		await $LevelCard/CardPlayer.animation_finished
		$LevelCard/CardPlayer.play("End")
		# unpause the game and set previous pause mode nodes to stop on pause
		get_tree().paused = false
		Global.musicParent.process_mode = PROCESS_MODE_PAUSABLE
		$LevelCard/CardPlayer.process_mode = PROCESS_MODE_PAUSABLE
		# emit stage start signal
		Global.emit_stage_start()
		# wait for title card animator to finish ending before starting the level timer
		await $LevelCard/CardPlayer.animation_finished
	else:
		get_tree().paused = true
		await get_tree().process_frame # delay unpausing for one frame so the player doesn't die immediately
		await get_tree().process_frame # second one needed for player 2
		# emit the stage start signal and start the stage
		Global.emit_stage_start()
		get_tree().paused = false
	Global.timerActive = true
	# replace "sonic" in stage clear to match the player clear string
	$LevelClear/Passed.text = $LevelClear/Passed.text.replace("SONIC",Global.get_character_name(Global.PlayerChar1))
	# set the act clear frame
	$LevelClear/Act.frame = act-1

func _process(delta):
	# set score string to match global score with leading 0s
	scoreText.text = "%6d" % Global.score
	
	# clamp time so that it won't go to 10 minutes
	var hud_time = min(Global.levelTime,Global.maxTime - 0.001)
	var hud_time_minutes: int = int(hud_time) / 60
	var hud_time_seconds: int = int(hud_time) % 60
	# set time text, format it to have a leading 0 so that it's always 2 digits
	match Global.time_tracking:
		Global.TIME_TRACKING_MODES.STANDARD:
			timeText.text = "%2d:%02d" % [hud_time_minutes,hud_time_seconds]
		Global.TIME_TRACKING_MODES.SONIC_CD:
			var hud_time_hundredths: int = int(hud_time * 100) % 100
			timeText.text = "%2d'%02d\"%02d" % [hud_time_minutes,hud_time_seconds,hud_time_hundredths]
	
	# cehck that there's player, if there is then track the focus players ring count
	if (Global.players.size() > 0):
		ringText.text = "%3d" % Global.players[focusPlayer].rings
	
	# track lives with leading 0s
	lifeText.text = "%2d" % Global.lives
	
	# Water Overlay
	
	# cehck that this level has water
	if Global.waterLevel != null:
		# get current camera
		var cam = GlobalFunctions.getCurrentCamera2D()
		if cam != null:
			# if camera exists place the water's y position based on the screen position as the water is a UI overlay
			$Water/WaterOverlay.position.y = clamp(Global.waterLevel-GlobalFunctions.getCurrentCamera2D().get_screen_center_position().y+(get_viewport().get_visible_rect().size.y/2),0,get_viewport().get_visible_rect().size.y)
		# scale water level to match the visible screen
		$Water/WaterOverlay.scale.y = clamp(Global.waterLevel-$Water/WaterOverlay.position.y,0,get_viewport().size.y)
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
							await get_tree().process_frame
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
	if Global.get_stage_clear_phase() >= Global.STAGE_CLEAR_PHASES.SCORE_TALLY:
		# initialize stage clear sequence
		if !isStageEnding:
			isStageEnding = true

			# reset air in case we are under water
			_reset_air()
			
			# show level clear elements
			$LevelClear.visible = true
			$LevelClear/Tally/ScoreNumber.text = scoreText.text
			$LevelClear/Animator.play("LevelClear")
			
			# set bonuses
			ringBonus = floor(Global.players[focusPlayer].rings)*100
			$LevelClear/Tally/RingNumbers.text = "%6d" % ringBonus
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
			$LevelClear/Tally/TimeNumbers.text = "%6d" % timeBonus
			# wait for counter wait time to count down
			$LevelClear/CounterWait.start()
			await $LevelClear/CounterWait.timeout
			# start the level counter tally (see _on_CounterCount_timeout)
			$LevelClear/CounterCount.start()
			# initially the tick sound isn't looped, so let's make it loop
			tick_looped.loop_mode = AudioStreamWAV.LOOP_FORWARD
			$LevelClear/Counter.play()
			await self.tally_clear
			# wait 2 seconds (reuse timer)
			$LevelClear/CounterWait.start(2)
			await $LevelClear/CounterWait.timeout
			# after clear, change to next level in Global.nextZone (you can set the next zone in the level script node)
			Global.main.change_scene_to_file(Global.nextZone,"FadeOut","FadeOut",1)
	
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
		Global.bossMusic.stop()
		Global.life.stop()
		# wait for animation to finish
		await $GameOver/GameOver.animation_finished
		# reset game
		if Global.levelTime < Global.maxTime or Global.lives <= 0:
			Global.main.change_scene_to_file(Global.startScene,"FadeOut")
			await Global.main.scene_faded
			Global.reset_values()
		# reset level (if time over and lives aren't out)
		else:
			Global.main.change_scene_to_file(null,"FadeOut")
			await Global.main.scene_faded
			Global.levelTime = 0

func _reset_air():
	for player in Global.players:
		player.airTimer = player.defaultAirTime

func _add_score(subtractFrom,delta):
	# Normally we add 100 points per frame at 60 FPS, but player's framerate may
	# be different. To accommodate for that, we count the number of points based
	# on time passed since the previous frame.
	accumulatedDelta += delta
	var standardDelta = 1.0 / 60.0
	var points = floor(accumulatedDelta / standardDelta) * 100
	if (points > subtractFrom):
		points = subtractFrom
	accumulatedDelta -= points / 100 * standardDelta
	# check if adding score would hit the life bonus
	Global.check_score_life(points)
	subtractFrom -= points
	Global.score += points
	return subtractFrom

# counter count down
func _on_CounterCount_timeout(delta):
	# reset air in case we are under water
	_reset_air()
	# decrease bonuses in order, if time bonus not 0 then count time down, then do the same for rings
	# if you add other bonuses (like perfect bonus) you'll want to add it to the end of the sequence before the end
	if timeBonus > 0:
		timeBonus = _add_score(timeBonus,delta)
	elif ringBonus > 0:
		ringBonus = _add_score(ringBonus,delta)
	else:
		# Don't stop the tick sound abruptly, just disable looping,
		# so it stops by itself after it plays until the end once
		tick_looped.loop_mode = AudioStreamWAV.LOOP_DISABLED
		# stop counter timer and play score sound
		$LevelClear/CounterCount.stop()
		$LevelClear/Score.play()
		# emit tally clear signal
		emit_signal("tally_clear")
	# set the level clear strings to the bonuses
	$LevelClear/Tally/ScoreNumber.text = scoreText.text
	$LevelClear/Tally/TimeNumbers.text = "%6d" % timeBonus
	$LevelClear/Tally/RingNumbers.text = "%6d" % ringBonus
	
