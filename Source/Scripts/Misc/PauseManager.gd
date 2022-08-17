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
# menu 1 (starting menu)
[
"options",
"sound 100",
"music 100",
"scale x1",
"full screen off",
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

var onOff = ["off","on"]
var clampSounds = [-40,6]
var soundStep = (1.0/4.0)
var zoomClamp = [1,6]

var menu = 0
var option = 0

func _ready():
	set_menu(menu)

func _input(event):
	# check if paused and visible, otherwise cancel it out
	if !get_tree().paused or !visible:
		return null
	
	if event.is_action_pressed("gm_down"):
		choose_option(option+1)
	elif event.is_action_pressed("gm_up"):
		choose_option(option-1)
	# switch toggles for options menu settings
	elif event.is_action("gm_left") or event.is_action("gm_right") and menu == 1:
		var inputDir = -1+int(event.is_action("gm_right"))*2
		
		# set audio busses
		var getBus = "SFX"
		if option > 0:
			getBus = "Music"
		var soundExample = [$MenuVert,$MenuMusicVolume]
		
		match(option):
			0, 1: # Volume
				soundExample[option].play()
				AudioServer.set_bus_volume_db(AudioServer.get_bus_index(getBus),clamp(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(getBus))+inputDir*soundStep,clampSounds[0],clampSounds[1]))
				AudioServer.set_bus_mute(AudioServer.get_bus_index(getBus),AudioServer.get_bus_volume_db(AudioServer.get_bus_index(getBus)) <= clampSounds[0])
			2: # Scale
				if event.is_action_pressed("gm_left") or event.is_action_pressed("gm_right"):
					Global.zoomSize = clamp(Global.zoomSize+inputDir,zoomClamp[0],zoomClamp[1])
					OS.set_window_size(get_viewport().get_visible_rect().size*Global.zoomSize)
		$PauseMenu/VBoxContainer.get_child(option+1).get_child(0).string = update_text(option+1)
	
	
	# menu button activate
	elif event.is_action_pressed("gm_pause") or event.is_action_pressed("gm_action"):
		match(menu): # menu handles
			0: # main menu
				match(option): # Options
					0: # continue
						if Global.main.wasPaused:
							# give frame so game doesn't immedaitely unpause
							yield(get_tree(),"idle_frame")
							Global.main.wasPaused = false
							get_tree().paused = false
							visible = false
					_: # Set menu to option
						set_menu(option)
			1: # options menu
				match(option): # Options
					3: # full screen
						OS.window_fullscreen = !OS.window_fullscreen
						$PauseMenu/VBoxContainer.get_child(option+1).get_child(0).string = update_text(option+1)
					4: # control menu
						Global.save_settings()
						set_menu(0)
						$"../ControllerMenu".visible = true
						visible = false
						Global.main.wasPaused = false
						get_tree().paused = true
					5: # back
						Global.save_settings()
						set_menu(0)
			2: # reset level
				match(option): # Options
					0: # cancel
						set_menu(0)
					1: # ok
						set_menu(0)
						visible = false
						Global.checkPointTime = 0
						Global.currentCheckPoint = -1
						Global.main.change_scene(null,"FadeOut")
			3: # quit option
				match(option): # Options
					0: # cancel
						set_menu(0)
					1: # ok
						yield(get_tree(),"idle_frame")
						Global.main.reset_game()
		
	

func choose_option(optionSet = option+1, playSound = true):
	$PauseMenu/VBoxContainer.get_child(option+1).modulate = Color.white
	option = wrapi(optionSet,0,menusText[menu].size()-1)
	$PauseMenu/VBoxContainer.get_child(option+1).modulate = Color(1,1,0)
	
	if playSound:
		$MenuVert.play()

func set_menu(menuID = 0):
	for i in $PauseMenu/VBoxContainer.get_children():
		i.queue_free()
	menu = menuID
	
	for i in menusText[menuID].size():
		var text = Text.instance()
		$PauseMenu/VBoxContainer.add_child(text)
		var getText = text.get_child(0)
		if menuID != 1:
			getText.string = menusText[menuID][i]
		else: # options menu settings
			getText.string = update_text(i)
		if i == 0: # set title option to red
			text.modulate = Color(1,0,0)
		if i == 1: # set default option to yellow
			text.modulate = Color(1,1,0)
	choose_option(0,false)


func update_text(textRow = 0):
	match(textRow):
		1: # Sound
			return "sound "+str(round(((AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))-clampSounds[0])/(-clampSounds[0]+clampSounds[1]))*100))
		2: # Music
			return "music "+str(round(((AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))-clampSounds[0])/(-clampSounds[0]+clampSounds[1]))*100))
		3: # Scale
			return "scale x"+str(Global.zoomSize)
		4: # Full screen
			return "full screen "+onOff[int(OS.window_fullscreen)]
		_: # Default
			return menusText[menu][textRow]
