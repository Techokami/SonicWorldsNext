extends Control

var playerControlIndex = 0
var clearEventStep = 0
var bindButton = null

var joyAxisNameList = [
"L Stick X axis",
"L Stick Y axis",
"R Stick X axis",
"R Stick Y axis",
"Generic 4th axis",
"Generic 5th axis",
"L Trigger",
"R Trigger",
"Generic 8th axis",
"Generic 9th axis",
"Axis max",
]

var defaultMap = []

func _ready():
	# get defaults before loading inputs
	for i in InputMap.get_actions():
		defaultMap.append(InputMap.get_action_list(i))
	# load config data
	load_data()

func _input(event):
	# check if control menu pressed
	if event.is_action_pressed("ui_control_menu"):
		# check that game isn't already paused (this can make problems)
		if !get_tree().paused or visible:
			visible = !visible
			get_tree().paused = visible
			check_deletion()
	
	# Clear inputs
	elif visible and event.is_action_pressed("ui_clear_action"):
		if clearEventStep == 0:
			clearEventStep += 1
		else:
			# remove events from action
			if bindButton != null:
				# check if player 2 settings
				var p2Text = ""
				# if player index is 1 then add _P2 to the p2Text
				if playerControlIndex == 1:
					p2Text = "_P2"
				# remove event action
				InputMap.action_erase_events (bindButton.bind+p2Text)
			
			# reset clear
			clearEventStep = 0
			update_display()
		check_deletion()

func _on_Confirm_pressed():
	if bindButton == null:
		# confirm button pressed, toggle pausing
		visible = !visible
		get_tree().paused = visible


func _on_PlayerSwap_pressed():
	if bindButton == null:
		playerControlIndex = int(!playerControlIndex)
		$PlayerSwap/Label.text = "Player "+str(int(playerControlIndex)+1)

func update_display():
	if bindButton != null:
		if InputMap.has_action(bindButton.bind):
			# check if player 2 settings
			var p2Text = ""
			# if player index is 1 then add _P2 to the p2Text
			if playerControlIndex == 1:
				p2Text = "_P2"
			var charList = ""
			var inputGets = InputMap.get_action_list(bindButton.bind+p2Text)
			for i in inputGets:
				if i is InputEventKey:
					charList += i.as_text()+", "
				elif i is InputEventJoypadButton:
					charList += "("+str(i.button_index)+"), "
				elif i is InputEventJoypadMotion:
					if i.axis < joyAxisNameList.size():
						charList += joyAxisNameList[i.axis]+"("+str(i.axis_value)+"), "
			
			$CurrentMapList.text = charList.left(charList.length()-2)
	else:
		$CurrentMapList.text = ""
		# reset clear
		clearEventStep = 0
		check_deletion()

func check_deletion():
	var strings = ["Press " + InputMap.get_action_list("ui_clear_action")[0].as_text() + " to clear", "Press " + InputMap.get_action_list("ui_clear_action")[0].as_text() + " to confirm"]
	$ClearInfo.text = strings[clearEventStep]


# save configuration data
func _on_SaveInputs_pressed():
	var file = ConfigFile.new()
	# save inputs
	var actionCount = 0
	for i in InputMap.get_actions(): # input names
		actionCount = 0
		for j in InputMap.get_action_list(i): # the keys
			# key storage is complex, here we keep a record of keys, gamepad buttons and gamepad axis's
			# prefix keys: K = Key, B = joypad Button, A = Axis, V = AxisValue
			if j is InputEventKey:
				file.set_value("controls","K"+str(actionCount)+i,j.get_scancode_with_modifiers())
			elif j is InputEventJoypadButton:
				file.set_value("controls","B"+str(actionCount)+i,j.button_index)
				file.set_value("controls","B"+str(actionCount)+i+"Device",j.device)
			elif j is InputEventJoypadMotion:
				file.set_value("controls","A"+str(actionCount)+i,j.axis)
				file.set_value("controls","V"+str(actionCount)+i,j.axis_value)
				file.set_value("controls","A"+str(actionCount)+i+"Device",j.device)
			# incease counters (prevents conflicts)
			actionCount += 1
	# save config and close
	file.save("user://Config.cfg")

# load config data
func load_data():
	var file = ConfigFile.new()
	var err = file.load("user://Config.cfg")
	if err != OK:
		return false # Return false as an error
	
	# load inputs
	var actionCount = 0
	for i in InputMap.get_actions(): # loop through input names
		# prefix keys: K = Key, B = joypad Button, A = Axis, V = AxisValue
		
		# check for any inputs, if any are found then remove binding
		if (file.has_section_key("controls","K0"+i) || 
		file.has_section_key("controls","B0"+i) ||
		file.has_section_key("controls","A0"+i) || 
		file.has_section_key("controls","V0"+i)):
			# clear input
			InputMap.action_erase_events(i)
		# check prefixes
		while (file.has_section_key("controls","K"+str(actionCount)+i) || 
		file.has_section_key("controls","B"+str(actionCount)+i) ||
		file.has_section_key("controls","A"+str(actionCount)+i) || 
		file.has_section_key("controls","V"+str(actionCount)+i)):
			
			# keyboard check
			if (file.has_section_key("controls","K"+str(actionCount)+i)):
				# define new key
				var getInput = InputEventKey.new()
				# grab scancode
				getInput.scancode = file.get_value("controls","K"+str(actionCount)+i)
				# set new input
				InputMap.action_add_event(i,getInput)
			# joypad button check
			if (file.has_section_key("controls","B"+str(actionCount)+i)):
				# define new key
				var getInput = InputEventJoypadButton.new()
				# grab button index
				getInput.button_index = file.get_value("controls","B"+str(actionCount)+i)
				# set device
				if (file.has_section_key("controls","B"+str(actionCount)+i+"Device")):
					getInput.device = file.get_value("controls","B"+str(actionCount)+i+"Device")
				# set new input
				InputMap.action_add_event(i,getInput)
			# joypad Axis check
			if (file.has_section_key("controls","A"+str(actionCount)+i) &&
			file.has_section_key("controls","V"+str(actionCount)+i)):
				# define new key
				var getInput = InputEventJoypadMotion.new()
				# grab axis
				getInput.axis = file.get_value("controls","A"+str(actionCount)+i)
				getInput.axis_value = file.get_value("controls","V"+str(actionCount)+i)
				# set device
				if (file.has_section_key("controls","A"+str(actionCount)+i+"Device")):
					getInput.device = file.get_value("controls","A"+str(actionCount)+i+"Device")
				# set new input
				InputMap.action_add_event(i,getInput)
			
			actionCount += 1
		# reset action counter
		actionCount = 0

# reset to defaults
func _on_Defaults_pressed():
	var getActions = InputMap.get_actions()
	for i in getActions.size():
		InputMap.action_erase_events(getActions[i])
		for j in defaultMap[i]:
			InputMap.action_add_event(getActions[i],j)
