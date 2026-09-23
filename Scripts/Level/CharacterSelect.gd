extends Node2D


@export var music: AudioStream = preload("res://Audio/Soundtrack/10. SWD_CharacterSelect.ogg")
## level labels, the amount of labels here determines the total amount of options
@export var levelLabels: Array[String] = [
	"Base Zone Act 1",
	"Base Zone Act 2",
	"Emerald Hill Zone"
]
## The path to each zone in the Filesystem.
@export var levelPaths: Array[String] = [
	"res://Scene/Zones/BaseZone.tscn",
	"res://Scene/Zones/BaseZoneAct2.tscn",
	"res://Scene/Zones/emerald_hill_zone.tscn",
]
var selected = false

var characters: Array[Dictionary] = [
	{ label="Sonic and Tails", char1=Global.CHARACTERS.SONIC,    char2=Global.CHARACTERS.TAILS },
	{ label="Sonic",           char1=Global.CHARACTERS.SONIC,    char2=Global.CHARACTERS.NONE },
	{ label="Tails",           char1=Global.CHARACTERS.TAILS,    char2=Global.CHARACTERS.NONE },
	{ label="Knuckles",        char1=Global.CHARACTERS.KNUCKLES, char2=Global.CHARACTERS.NONE },
	{ label="Amy",             char1=Global.CHARACTERS.AMY,      char2=Global.CHARACTERS.NONE },
]

var characterID = 0
# Used to toggle visibility of character sprites (initialized in `_ready()`)
var characterSprites = []
# level id lines up with levelLabels
var levelID = 0

# Used to avoid repeated detection of inputs with analog stick
var lastInput: Vector2i = Vector2i.ZERO
# Used to avoid repeated ditection of inputs from buttons
var action_was_pressed_last_frame = false

func _ready():
	cheats_ready()
	MusicController.reset_music_themes()
	MusicController.set_level_music(music)
	$UI/Labels/Control/Character.text = characters[characterID].label
	$UI/Labels/Control/MutliplayerMode.text = Global.MULTIMODE.find_key(Global.get_multimode())

	for child in $UI/Labels/CharacterOrigin.get_children():
		if child is Node2D or child is Sprite2D:
			characterSprites.append(child)
	assert(characters.size() <= characterSprites.size())

func update_character_picks() -> void:
		# turn on and off visibility of the characters based on the current selection
	for i in characterSprites.size():
		characterSprites[i].visible = (characterID == i)
	pass
	$UI/Labels/Control/Character.text = characters[characterID].label
	# set the character
	Global.PlayerChar1 = characters[characterID].char1
	Global.PlayerChar2 = characters[characterID].char2

func _input(event):
	
	if !selected:
		# get inputs and round them to the nearest integer,
		# so X and Y are either, 1, 0 or -1
		var inputCue: Vector2i = Vector2i(Input.get_vector("gm_left","gm_right","gm_up","gm_down").round())
		if inputCue.x != lastInput.x and inputCue.x != 0:
			# select character rotation
			# `inputCue.x` is either 1 or -1, so `characterID+inputCue.x` will effectively
			# result in the previous/next character ID when the player presses left/right
			characterID = wrapi(characterID+inputCue.x,0,characters.size())
			$Switch.play()
		if inputCue.y != lastInput.y and inputCue.y != 0:
			# `inputCue.y` is either 1 or -1, so `levelID+inputCue.y` will effectively
			# result in the previous/next level ID when the player presses up/down
			levelID = wrapi(levelID+inputCue.y,0,levelLabels.size())
			$UI/Labels/Control/Level.text = levelLabels[levelID]
			$Switch.play()
		#Save previous input for next read
		lastInput = inputCue
		
		# shifts graphics for the chosen player
		update_character_picks()
		
		# Cycle multiplayer mode on 'A' press
		if event.is_action_pressed("gm_action"):
			if !action_was_pressed_last_frame:
				change_multiplayer_mode()
				action_was_pressed_last_frame = true
		else:
			action_was_pressed_last_frame = false
		
		# finish character select if start is pressed
		if event.is_action_pressed("gm_pause"):
			selected = true
			
			# set the character
			Global.PlayerChar1 = characters[characterID].char1
			Global.PlayerChar2 = characters[characterID].char2
			
			# Save the selected zone ID
			Global.currentZone = levelPaths[levelID]
			Main.change_scene(Global.currentZone,"FadeOut",1.0,true)
			
func change_multiplayer_mode():
	Global.cycle_multimode()
	$UI/Labels/Control/MutliplayerMode.text = Global.MULTIMODE.find_key(Global.get_multimode())



# CHEATS SECTION
# Code below this point is just used for cheat codes
# Player Select Screen cheats are currently entered via pressing the normal number keys. They might
# fail if you bind these keys for some reason. No idea if the numpad works or not.
# Dynamic buffer storing current cheat code input
var cheat_buffer: Array[String] = []
# Maximum length of cheat buffer currently large enough to store a date in YYYYMMDD format
const MAX_CHEAT_BUFFER_SIZE: int = 8
# Shadow isn't incldued by default, so we need a dict for him.
var CHARACTER_SHADOW := { label="Shadow (PREVIEW)", char1=Global.CHARACTERS.SHADOW, char2=Global.CHARACTERS.NONE }
# Cheat tracking dictionary
# Structure: "sequence_string": {"function": String, "state": int}
var cheats: Dictionary = {
	"19910623": {
		"function": "sonic_cheat",
	},
	"19921124": {
		"function": "tails_cheat",
	},
	"19931119": {
		"function": "amy_cheat",
	},
	"19941019": {
		"function": "knuckles_cheat",
	},
	"20010619": {
		"function": "shadow_cheat",
	},
}

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
		
	if event is InputEventKey and event.pressed:
		var key_code: Key = event.keycode
		
		# Check for standard top-row number keys (KEY_0 to KEY_9)
		if key_code >= KEY_0 and key_code <= KEY_9:
			var digit_str: String = str(key_code - KEY_0)
			_add_to_cheat_buffer(digit_str)

func _add_to_cheat_buffer(digit: String) -> void:
	# Add the new digit to the end
	cheat_buffer.append(digit)
	
	# Drop the oldest entry if size exceeds 8
	if cheat_buffer.size() > MAX_CHEAT_BUFFER_SIZE:
		cheat_buffer.pop_front()
	
    # Flatten the array of strings into a single string sequence
	var entered_sequence: String = "".join(cheat_buffer)
	
	# Check if the sequence exists in our dictionary
	if cheats.has(entered_sequence):
		var cheat_data: Dictionary = cheats[entered_sequence]
		var function_name: String = cheat_data["function"]
		
		if has_method(function_name):
			Callable(self, function_name).call(cheats[entered_sequence])
			
			# Optional: Clear the buffer after a successful activation 
			# so the user doesn't accidentally trigger things repeatedly
			cheat_buffer.clear()
			
func set_all_partners(character: Global.CHARACTERS) -> void:
	for i in range(1, characters.size()):
		characters[i].char2 = character

## If anything cheat related needs to be set on scene ready, do it here.
func cheats_ready():
	if Global.shadow_enabled:
		characters.append(CHARACTER_SHADOW)

func sonic_cheat(cheat: Dictionary) -> void:
	$Cheats/SonicCheat.play()
	set_all_partners(Global.CHARACTERS.SONIC)
	
func tails_cheat(cheat: Dictionary) -> void:
	$Cheats/TailsCheat.play()
	set_all_partners(Global.CHARACTERS.TAILS)

func amy_cheat(cheat: Dictionary) -> void:
	$Cheats/AmyCheat.play()
	set_all_partners(Global.CHARACTERS.AMY)

func knuckles_cheat(cheat: Dictionary) -> void:
	$Cheats/KnucklesCheat.play()
	set_all_partners(Global.CHARACTERS.KNUCKLES)

func shadow_cheat(cheat: Dictionary) -> void:
	# If the cheat hasn't been activated before, we need to add Shadow to selectable characters
	if !(Global.shadow_enabled):
		$Cheats/ShadowCheat.play()
		Global.shadow_enabled = true
		characters.append(CHARACTER_SHADOW)
		characterID = characterSprites.size() - 1

	# If activated a second time or developer has defaulted Shadow to enabled, we set the partner
	# character for all normally solo options to Shadow instead
	else:
		$Cheats/ShadowCheat2.play()
		set_all_partners(Global.CHARACTERS.SHADOW)
		
	
	update_character_picks()
