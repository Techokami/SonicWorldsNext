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
		if !get_tree().paused:
			wasPaused = false
		
		if !wasPaused and !get_tree().paused:
			# Do the pause
			wasPaused = true
			get_tree().paused = true
			
		elif wasPaused and get_tree().paused:
			# Do the unpause
			get_tree().paused = false
	# reset game
	if event.is_action_pressed("ui_reset"):
		wasPaused = false
		Global.reset_values()
		get_tree().paused = false
		get_tree().reload_current_scene()



func change_scene(scene = null, fadeOut = "", fadeIn = "", setType = "SetSub", length = 1):
	
	$GUI/Fader.playback_speed = 1/length
	
	$GUI/Fader.play(setType)
	
	if fadeOut != "":
		$GUI/Fader.queue(fadeOut)
		yield($GUI/Fader,"animation_finished")
	
	
	for i in $SceneLoader.get_children():
		i.queue_free()
	# Error prevention
	emit_signal("scene_faded")
	yield(get_tree(),"idle_frame")
	Global.players = []
	Global.checkPoints = []
	if Global.stageClearPhase != 0:
		Global.currentCheckPoint = -1
		Global.levelTime = 0
	Global.globalTimer = 0
	Global.stageClearPhase = 0
	Global.waterLevel = null
	Global.gameOver = false
	sceneCanPause = false
	
	if scene == null:
		if lastScene != null:
			$SceneLoader.add_child(lastScene.instance())
	else:
		$SceneLoader.add_child(scene.instance())
		lastScene = scene

	if fadeIn != "":
		$GUI/Fader.play_backwards(fadeIn)
	elif fadeOut != "":
		$GUI/Fader.play("RESET")


func _on_Life_finished():
	set_volume()

func set_volume(volume = 0):
	startVolumeLevel = Global.music.volume_db
	setVolumeLevel = volume
	volumeLerp = 0


