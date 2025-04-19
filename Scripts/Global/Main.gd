class_name MainGameScene
extends Node2D

# last scene is used for referencing the current scene (this is used for stage restarting)
var lastScene = null

# this gets emitted when the scene fades, used to load in level details and data to hide it from the player
signal scene_faded
# signal that emits when volume fades
signal volume_set

# note: volumes can be set with set_volume(), these variables are just for volume control reference
var startVolumeLevel = 0 # used as reference for when a volume change started
var setVolumeLevel = 0 # where to fade the volume to
var volumeLerp = 0 # current stage between start and set for volume level
var volumeFadeSpeed = 1 # speed for volume changing

# was paused enables menu control when the player pauses manually so they don't get stuck (get_tree().paused may want to be used by other instances)
var wasPaused = false
# determines if the current scene can pause
var sceneCanPause = false

func _ready():
	# global object references
	Global.main = self
	Global.musicParent = get_node_or_null("Music")
	Global.music = get_node_or_null("Music/Music")
	Global.bossMusic = get_node_or_null("Music/BossTheme")
	Global.effectTheme = get_node_or_null("Music/EffectTheme")
	Global.drowning = get_node_or_null("Music/Drowning")
	Global.life = get_node_or_null("Music/Life")
	# initialize game data using global reset (it's better then assigning variables twice)
	Global.reset_values()

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

# reset game function
func reset_game():
	# remove the was paused check
	wasPaused = false
	# reset game values
	Global.reset_values()
	# unpause scene (if it was)
	get_tree().paused = false
	# Godot doesn't like returning values with empty variables so create a dummy variable for it to assign
	var _con = get_tree().reload_current_scene()

# change scene function
# scene = the scene instance to load (load("res...")
# fadeOut = the fade out animation to play from the Fader animation node (set to "" for instant)
# fadeIn = the fade in animation to play from the Fader animation node after a scene has finished it's fading out (set to "" for instant)
# setType = play an animation before either fades, this is mostly used for setting up blending modes. this is mostly used for setting to either blend add colours or blend remove but you can put whatever animation you want here
# length = time in seconds for the fade animations to play
# storeScene = should the current scene be storred? (not the new one being loaded)
# NOTE: if there's already a scene saved then the next time storeScene is called then the stored scene will be loaded instead before it gets removed
# resetData = should the level data be reset between scenes (this is needed for storeScene if you're storing a level so that level times and object references don't get reset)
func change_scene_to_file(scene = null, fadeOut = "", fadeIn = "", length = 1, storeScene = false, resetData = true):
	# stop pausing
	sceneCanPause = false
	# set fader speed
	$GUI/Fader.speed_scale = 1.0/float(length)
	
	# if fadeOut isn't blank, play the fade out animation and then wait, otherwise skip this
	if fadeOut != "":
		$GUI/Fader.queue(fadeOut)
		await $GUI/Fader.animation_finished
	
	# error prevention
	scene_faded.emit()
	
	# use restoreScene to tell if we're restoring a scene
	var restoreScene = false
	# storeScene will only remember the first child of scene loader, this will be referenced later
	if storeScene:
		# clear memory if it's already occupied
		if is_instance_valid(Global.stageInstanceMemory):
			# we're restoring a scene so set restoreScene to true so the scene can be loaded after fading
			restoreScene = true
		# if stage memory is empty, add current scene
		else:
			Global.stageInstanceMemory = $SceneLoader.get_child(0)
			$SceneLoader.remove_child(Global.stageInstanceMemory)
	
	# clear scene
	for i in $SceneLoader.get_children():
		i.queue_free()
	
	await get_tree().process_frame
	# reset data level data, if reset data is true
	if resetData:
		Global.players = []
		Global.checkPoints = []
		Global.waterLevel = null
		Global.gameOver = false
		if Global.stageClearPhase != 0:
			Global.currentCheckPoint = -1
			Global.levelTime = 0
			Global.timerActive = false
		Global.globalTimer = 0
		Global.stageClearPhase = 0
	
	# check if to restore scene
	if restoreScene:
		# add stored scene to scene loader
		$SceneLoader.add_child(Global.stageInstanceMemory)
		# check if the scene has a function called "level_reset_data"
		# if it does then execute it so the level can run any scripts it needs to for a level start
		# this is mostly used in the level manager to play the title card again
		if Global.stageInstanceMemory.has_method("level_reset_data"):
			Global.stageInstanceMemory.level_reset_data()
		# set last scene to the stage load memory path
		lastScene = Global.stageLoadMemory
		# reset stageInstanceMemory
		Global.stageInstanceMemory = null
	else:
	# create new scene
		if scene == null:
			if lastScene != null:
				$SceneLoader.add_child(lastScene.instantiate())
		else:
			$SceneLoader.add_child(scene.instantiate())
			lastScene = scene
			# don't know if the current scene is gonna be stored in memory so store last scene to global state load memory
			# check there's not a stored scene first
			if !is_instance_valid(Global.stageInstanceMemory):
				Global.stageLoadMemory = lastScene
	
	# play fade in animation if it's not blank
	if fadeIn != "":
		$GUI/Fader.play_backwards(fadeIn)
	# if fadeOut wasn't set either then just reset the fader
	elif fadeOut != "":
		$GUI/Fader.play("RESET")
	
	# stop life sound (if it's still playing)
	if Global.life.is_playing():
		Global.life.stop()
		# set volume level to default
		Global.music.volume_db = 0
		# copy the volume to other songs (you'll want to add yours here if you add more)
		Global.bossMusic.volume_db = Global.bossMusic.volume_db
		Global.effectTheme.volume_db = Global.music.volume_db
		Global.drowning.volume_db = Global.music.volume_db

# executed when life sound has finished
func _on_Life_finished():
	# set volume level to default
	set_volume()

# set the volume level
func set_volume(volume = 0, fadeSpeed = 1):
	# set the start volume level to the current volume
	startVolumeLevel = Global.music.volume_db
	# set the volume level to go to
	setVolumeLevel = volume
	# set volume transition
	volumeLerp = 0
	# set the speed for the transition
	volumeFadeSpeed = fadeSpeed
	# this is continued in _process() as it needs to run during gameplay
