class_name MainGameScene
extends Node2D

# this gets emited when the scene fades, used to load in level details and data to hide it from the player
signal scene_faded
# signal that emits when volume fades
signal volume_set

# note: volumes can be set with set_volume(), these variables are just for volume control reference
var startVolumeLevel = 0 # used as reference for when a volume change started
var setVolumeLevel = 0 # where to fade the volume to
var volumeLerp = 0 # current stage between start and set for volume level
var volumeFadeSpeed = 1 # speed for volume changing

# was paused enables menu control when the player pauses manually so they don't get stuck (get_tree().paused may want to be used by other intances)
var wasPaused = false
# determines if the current scene can pause
var sceneCanPause = false

func _ready():
	# global object references
	Global.musicParent = get_node_or_null("Music")
	Global.music = get_node_or_null("Music/Music")
	Global.bossMusic = get_node_or_null("Music/BossTheme")
	Global.effectTheme = get_node_or_null("Music/EffectTheme")
	Global.drowning = get_node_or_null("Music/Drowning")
	Global.life = get_node_or_null("Music/Life")
	# initialize game data using global reset (it's better then assigning variables twice)
	reset_game_values()

func _process(delta):
	# verify scene isn't paused
	if !get_tree().paused and Global.music != null:
		# pause main music if effect theme, boss music or drowning songs are playing
		Global.music.stream_paused = Global.effectTheme.playing or Global.drowning.playing or Global.bossMusic.playing
		# pause boss music if drowning
		Global.bossMusic.stream_paused = Global.drowning.playing
		# pause effect music if drowning
		Global.effectTheme.stream_paused = Global.drowning.playing or Global.bossMusic.playing
		
		# check that volume lerp isn't transitioned yet
		if volumeLerp < 1:
			# move volume lerp to 1
			volumeLerp = move_toward(volumeLerp,1,delta*volumeFadeSpeed)
			# use volume lerp to set the effect volume
			Global.music.volume_db = lerp(float(startVolumeLevel),float(setVolumeLevel),float(volumeLerp))
			# copy the volume to other songs (you'll want to add yours here if you add more)
			Global.effectTheme.volume_db = Global.music.volume_db
			Global.drowning.volume_db = Global.music.volume_db
			Global.bossMusic.volume_db = Global.music.volume_db
			if volumeLerp >= 1:
				volume_set.emit()

func _input(event):
	# Pausing
	if event.is_action_pressed("gm_pause") and sceneCanPause:
		# check if the game wasn't paused and the tree isn't paused either
		if !wasPaused and !get_tree().paused:
			# Do the pause
			wasPaused = true
			get_tree().paused = true
			$GUI/Pause.visible = true
		# else if the scene was paused manually and the game was paused, check that the gui menu isn't visible and unpause
		# Note: the gui menu has some settings to unpause itself so we don't want to override that while the user is in the settings
		elif wasPaused and get_tree().paused and !$GUI/Pause.visible:
			# Do the unpause
			wasPaused = false
			get_tree().paused = false
	# reset game if F2 is pressed (this button can be changed in project settings)
	if event.is_action_pressed("ui_reset"):
		reset_game()

## Reset Game
func reset_game():
	# remove the was paused check
	wasPaused = false
	sceneCanPause = false
	# reset game values
	reset_game_values()
	# unpause scene (if it was)
	get_tree().paused = false
	Global.effectTheme.stop()
	Global.bossMusic.stop()
	Global.music.stop()
	# Godot doesn't like returning values with empty variables so create a dummy variable for it to assign
	change_scene("res://Scene/Presentation/PoweredByWorlds.tscn")

## New Scene Change function. Args: Scene path, fade animation, time of transition, reset data
func change_scene(scene: String, fade_anim: String = "FadeOut", length: float = 1.0, resetData:bool = true):
	$GUI/Fader.speed_scale = 1.0/float(length)
	# if fadeOut isn't blank, play the fade out animation and then wait, otherwise skip this
	if fade_anim != "":
		$GUI/Fader.queue(fade_anim)
		await $GUI/Fader.animation_finished
	# error prevention
	emit_signal("scene_faded")
	await get_tree().process_frame
	get_tree().paused = false
	$GUI/Pause.hide()
	Global.music.stop()
	get_tree().change_scene_to_file(scene)
	# reset data level data, if reset data is true
	if resetData:
		clear_dynamic_level_variables()
	else:
		Global.players.clear()
		Global.checkPoints.clear()
	# play fade in animation back if it's not blank
	if fade_anim != "":
		$GUI/Fader.play_backwards(fade_anim)


func clear_dynamic_level_variables():
	Global.players.clear()
	Global.checkPoints.clear()
	Global.waterLevel = null
	Global.gameOver = false
	if Global.stageClearPhase != 0:
		Global.currentCheckPoint = -1
		Global.levelTime = 0
		Global.timerActive = false
	Global.bonus_stage_saved_position = Vector2.ZERO
	Global.bonus_stage_saved_rings = 0
	Global.bonus_stage_saved_time = 0.0
	Global.checkPointTime = 0
	Global.globalTimer = 0
	Global.stageClearPhase = 0
	Global.nodeMemory.clear()


# reset values, self explanatory, put any variables to their defaults in here
func reset_game_values():
	Global.lives = 3
	Global.score = 0
	Global.continues = 0
	Global.levelTime = 0
	Global.emeralds = 0
	Global.specialStageID = 0
	Global.checkPoints = []
	Global.checkPointTime = 0
	Global.currentCheckPoint = -1
	Global.animals = [0,1]
	Global.nodeMemory.clear()
	Global.nextZone = "res://Scene/Zones/BaseZone.tscn"


# executed when life sound has finished
func _on_Life_finished():
	# set volume level to default
	set_volume()

# set the volume level
func set_volume(volume = 0, fadeSpeed = 1):
	# set the start volume level to the curren volume
	startVolumeLevel = Global.music.volume_db
	# set the volume level to go to
	setVolumeLevel = volume
	# set volume transition
	volumeLerp = 0
	# set the speed for the transition
	volumeFadeSpeed = fadeSpeed
	# this is continued in _process() as it needs to run during gameplay
