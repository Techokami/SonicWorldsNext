extends Node2D

var lastScene = null

signal scene_faded

var startVolumeLevel = 0
var setVolumeLevel = 0
var volumeLerp = 0

var wasPaused = false
var sceneCanPause = false

func _ready():
	Global.main = self
	Global.musicParent = $Music
	Global.music = $Music/Music
	Global.effectTheme = $Music/EffectTheme
	Global.drowning = $Music/Downing
	Global.life = $Music/Life
	Global.reset_values()
	# give game a frame wait time to ensure the game loads first
	yield(get_tree(),"idle_frame")

func _process(delta):
	if !get_tree().paused:
		Global.music.stream_paused = Global.effectTheme.playing or Global.drowning.playing
		Global.effectTheme.stream_paused = Global.drowning.playing
	
		if volumeLerp < 1:
			volumeLerp = clamp(volumeLerp+delta,0,1)
			Global.music.volume_db = lerp(startVolumeLevel,setVolumeLevel,volumeLerp)
			Global.effectTheme.volume_db = Global.music.volume_db
			Global.drowning.volume_db = Global.music.volume_db

func _input(event):
	# Pausing
	if event.is_action_pressed("gm_pause") and sceneCanPause:
		if !wasPaused and !get_tree().paused:
			# Do the pause
			wasPaused = true
			get_tree().paused = true
			$GUI/Pause.visible = true
			
		elif wasPaused and get_tree().paused and !$GUI/Pause.visible:
			# Do the unpause
			wasPaused = false
			get_tree().paused = false
		
		
	
	# reset game
	if event.is_action_pressed("ui_reset"):
		reset_game()


func reset_game():
	wasPaused = false
	Global.reset_values()
	get_tree().paused = false
	var _con = get_tree().reload_current_scene()


func change_scene(scene = null, fadeOut = "", fadeIn = "", setType = "SetSub", length = 1, storeScene = false, resetData = true):
	
	sceneCanPause = false
	$GUI/Fader.playback_speed = 1/length
	
	$GUI/Fader.play(setType)
	
	if fadeOut != "":
		$GUI/Fader.queue(fadeOut)
		yield($GUI/Fader,"animation_finished")
	
	var restoreScene = false
	# storeScene will only remember the first child of scene loader
	if storeScene:
		# clear memory if it's already occupied
		if is_instance_valid(Global.stageInstanceMemory):
			restoreScene = true
		# if stage memory is empty, add current scene
		else:
			Global.stageInstanceMemory = $SceneLoader.get_child(0)
			$SceneLoader.remove_child(Global.stageInstanceMemory)
	
	# clear scene
	for i in $SceneLoader.get_children():
		i.queue_free()
	
	# Error prevention
	emit_signal("scene_faded")
	yield(get_tree(),"idle_frame")
	# reset data if true
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
	
	# check for restore scene
	if restoreScene:
		$SceneLoader.add_child(Global.stageInstanceMemory)
		if Global.stageInstanceMemory.has_method("level_reset_data"):
			Global.stageInstanceMemory.level_reset_data()
		lastScene = Global.stageLoadMemory
		# reset stageInstanceMemory
		Global.stageInstanceMemory = null
	else:
	# create new scene
		if scene == null:
			if lastScene != null:
				$SceneLoader.add_child(lastScene.instance())
		else:
			$SceneLoader.add_child(scene.instance())
			lastScene = scene
			# don't know if the current scene is gonna be stored in memory so store last scene to global state load memory
			# if the current instance memory is invalid
			if !is_instance_valid(Global.stageInstanceMemory):
				Global.stageLoadMemory = lastScene
	
	if fadeIn != "":
		$GUI/Fader.play_backwards(fadeIn)
	elif fadeOut != "":
		$GUI/Fader.play("RESET")
	# wait for scene to load


func _on_Life_finished():
	set_volume()

func set_volume(volume = 0):
	startVolumeLevel = Global.music.volume_db
	setVolumeLevel = volume
	volumeLerp = 0

