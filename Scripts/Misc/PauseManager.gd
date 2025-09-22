extends Control

var Text = preload("res://Entities/Misc/PauseMenuText.tscn")

# note: first option in an array is the title, it can't be selected
var menusText = [
# menu 0 (starting menu)
[
"pause",
"continue",
"options",
"restart",
"quit",],
# menu 1 (options menu)
[
"options",
"sound 100",
"music 100",
"scale x1",
"full screen off",
"smooth rotation off",
"time tracking",
"controls",
"back",],
# menu 2 (restart menu confirm)
[
"restart",
"cancel",
"ok",],
# menu 3 (quit game confirm)
[
"quit",
"cancel",
"ok",],
]

# on or off strings
var onOff = ["off","on"]
# clamp for minimum and maximum sound volume (muted when audio is at lowest)
var clampSounds = [-40.0,6.0]
# how much to iterate through (take the total sum then divide it by how many steps we want)
@onready var soundStep = (abs(clampSounds[0])+abs(clampSounds[1]))/100.0
# button delay
var soundStepDelay = 0
var subSoundStep = 1.0
# screen size limit
var zoomClamp = [1,6]

var menu = 0 # current menu option
enum MENUS {MAIN, OPTIONS, RESTART, QUIT}
var option = 0
# Used to avoid repeated detection of inputs with analog stick
var lastInput = Vector2.ZERO

func _ready():
	set_menu(menu)

func _process(_delta):
	# check if paused and visible, otherwise cancel it out
	if !get_tree().paused or !visible:
		return null
	do_lateral_input()

func _input(event):
	# check if paused and visible, otherwise cancel it out
	if !get_tree().paused or !visible:
		return null

	# menu button activate
	if event.is_action_pressed("gm_pause") or event.is_action_pressed("gm_action"):
		match(menu): # menu handles
			MENUS.MAIN: # main menu
				match(option): # Options
					0: # continue
						if Global.main.wasPaused:
							# give frame so game doesn't immedaitely unpause
							await get_tree().process_frame
							Global.main.wasPaused = false
							get_tree().paused = false
							visible = false
					_: # Set menu to option
						set_menu(option)
			MENUS.OPTIONS: # options menu
				match(option): # Options
					3: # full screen
						get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (!((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED
						$PauseMenu/VBoxContainer.get_child(option+1).get_child(0).text = update_text(option+1)
					4: # smooth rotation
						Global.smoothRotation = (Global.smoothRotation + 1) % 2
						$PauseMenu/VBoxContainer.get_child(option+1).get_child(0).text = update_text(option+1)
					5: # time tracking
						Global.time_tracking = ((Global.time_tracking + 1) % Global.TIME_TRACKING_MODES.size()) as Global.TIME_TRACKING_MODES
						$PauseMenu/VBoxContainer.get_child(option+1).get_child(0).text = update_text(option+1)
					6: # control menu
						Global.save_settings()
						set_menu(0)
						$"../ControllerMenu".visible = true
						visible = false
						Global.main.wasPaused = false
						get_tree().paused = true
					7: # back
						Global.save_settings()
						set_menu(0)
			MENUS.RESTART: # reset level
				match(option): # Options
					0: # cancel
						set_menu(0)
					1: # ok
						set_menu(0)
						Global.main.wasPaused = false
						visible = false
						Global.checkPointTime = 0
						Global.currentCheckPoint = -1
						Global.main.change_scene_to_file(null,"FadeOut")
						#await Global.main.scene_faded
						MusicController.reset_music_themes()
			MENUS.QUIT: # quit option
				match(option): # Options
					0: # cancel
						set_menu(0)
					1: # ok
						await get_tree().process_frame
						MusicController.reset_music_themes()
						Global.main.reset_game()

func do_lateral_input():

	var inputCue: Vector2i = Vector2i(Input.get_vector("gm_left","gm_right","gm_up","ui_down").round())
	
	if inputCue.x != 0 and subSoundStep == 0:
		subSoundStep = 5.0
		soundStepDelay = 0
	
	# change menu options
	if inputCue.y != lastInput.y and inputCue.y != 0:
		# `inputCue.y` is either 1 or -1, so `option+inputCue.y` will effectively
		# result in the previous/next option when the player presses up/down
		choose_option(option+inputCue.y)
	
	# Volume controls
	elif inputCue.x != 0 and menu == MENUS.OPTIONS:
		var inputDir = inputCue.x
		
		# set audio busses
		var getBus: String = "SFX" if option == 0 else "Music"
		var soundExample = [$MenuVert,$MenuMusicVolume]
		
		match(option):
			0, 1: # Volume
				if soundStepDelay <= 0:
					soundExample[option].play()
					AudioServer.set_bus_volume_db(AudioServer.get_bus_index(getBus),clamp(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(getBus))+inputDir*soundStep,clampSounds[0],clampSounds[1]))
					AudioServer.set_bus_mute(AudioServer.get_bus_index(getBus),AudioServer.get_bus_volume_db(AudioServer.get_bus_index(getBus)) <= clampSounds[0])
					soundStepDelay = subSoundStep
				else:
					soundStepDelay -= 0.1
			2: # Scale
				if inputCue.x != 0 and inputCue != lastInput:
					
					var zoom_size = Global.get_zoom_size()
					zoom_size = clamp(zoom_size+inputDir,zoomClamp[0],zoomClamp[1])
					Global.resize_window(zoom_size)
					
		$PauseMenu/VBoxContainer.get_child(option+1).get_child(0).text = update_text(option+1)
	lastInput = inputCue

func choose_option(optionSet = option+1, playSound = true):
	# reset curren option colour to white
	$PauseMenu/VBoxContainer.get_child(option+1).modulate = Color.WHITE
	# change to new option, set the new option colour to yellow
	option = wrapi(optionSet,0,menusText[menu].size()-1)
	$PauseMenu/VBoxContainer.get_child(option+1).modulate = Color(1,1,0)
	
	if playSound:
		$MenuVert.play()

func set_menu(menuID = 0):
	# clear all current text nodes
	for i in $PauseMenu/VBoxContainer.get_children():
		i.queue_free()
	# set new menu
	menu = menuID
	
	# loop through menu lists and create a text node for each option
	for i in menusText[menuID].size():
		var text = Text.instantiate()
		$PauseMenu/VBoxContainer.add_child(text)
		var getText = text.get_child(0)
		if menuID != 1:
			getText.text = menusText[menuID][i]
		else: # options menu settings
			getText.text = update_text(i)
		if i == 0: # set title option to red
			text.modulate = Color(1,0,0)
		if i == 1: # set default option to yellow
			text.modulate = Color(1,1,0)
	# reset option (prevents going beyond the current option list)
	choose_option(0,false)


# updates for the option menu texts
func update_text(textRow = 0):
	match(textRow):
		1: # Sound
			return "sound "+str(round(((AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))-clampSounds[0])/(abs(clampSounds[0])+abs(clampSounds[1])))*100))
		2: # Music
			return "music "+str(round(((AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))-clampSounds[0])/(abs(clampSounds[0])+abs(clampSounds[1])))*100))
		3: # Scale
			return "scale x"+str(Global.get_zoom_size())
		4: # Full screen
			return "full screen "+onOff[int(((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)))]
		5: # Smooth Rotation
			return "smooth rotation " + onOff[Global.smoothRotation]
		6: # Time tracking
			return "time tracking " + Global.TIME_TRACKING_MODES.find_key(Global.time_tracking).capitalize().to_lower()
		_: # Default
			return menusText[menu][textRow]
