class_name MainGameScene
extends Node2D

# this gets emited when the scene fades, used to load in level details and data to hide it from the player
signal scene_faded

# was paused enables menu control when the player pauses manually so they don't get stuck (get_tree().paused may want to be used by other intances)
var wasPaused = false
# determines if the current scene can pause
var sceneCanPause = false

func _ready():
	# initialize game data using global reset (it's better then assigning variables twice)
	reset_values()

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

# reset game function
func reset_game():
	# remove the was paused check
	wasPaused = false
	sceneCanPause = false
	# reset game values
	reset_values()
	# unpause scene (if it was)
	get_tree().paused = false
	# Godot doesn't like returning values with empty variables so create a dummy variable for it to assign
	change_scene("res://Scene/Presentation/Title.tscn")

## New Scene Change function. Args: Scene path, fade animation, transition time, if saved data should be reset.
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
	MusicController.stop_all_music_themes()
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

## Clear dynamic variable when loading a level. Only use this when not loading from a special/bonus stage.
func clear_dynamic_level_variables():
	Global.players.clear()
	Global.checkPoints.clear()
	Global.waterLevel = null
	Global.gameOver = false
	if Global.is_in_any_stage_clear_phase():
		Global.currentCheckPoint = -1
		Global.levelTime = 0
		Global.timerActive = false
	
	Global.bonusStageSavedPosition = Vector2.ZERO
	Global.bonusStageSavedRings = 0
	Global.bonusStageSavedTime = 0.0
	
	Global.reset_stage_clear_phase()
	Global.nodeMemory.clear()

## reset values, self explanatory, put any variables to their defaults in here
func reset_values():
	Global.lives = 3
	Global.score = 0
	Global.continues = 0
	Global.levelTime = 0
	Global.emeralds = 0
	Global.specialStageID = 0
	Global.checkPoints.clear()
	Global.checkPointTime = 0
	Global.currentCheckPoint = -1
	Global.animals = [Animal.ANIMAL_TYPE.BIRD, Animal.ANIMAL_TYPE.SQUIRREL]
	Global.nodeMemory.clear()
	Global.nextZone = "res://Scene/Zones/BaseZone.tscn"
