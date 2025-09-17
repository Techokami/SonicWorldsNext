extends Node2D


@export var music: AudioStream = preload("res://Audio/Soundtrack/10. SWD_CharacterSelect.ogg")
@export var nextZone = load("res://Scene/Zones/BaseZone.tscn")
var selected = false

const characters: Array[Dictionary] = [
	{ label="Sonic and Tails", char1=Global.CHARACTERS.SONIC,    char2=Global.CHARACTERS.TAILS },
	{ label="Sonic",           char1=Global.CHARACTERS.SONIC,    char2=Global.CHARACTERS.NONE },
	{ label="Tails",           char1=Global.CHARACTERS.TAILS,    char2=Global.CHARACTERS.NONE },
	{ label="Knuckles",        char1=Global.CHARACTERS.KNUCKLES, char2=Global.CHARACTERS.NONE },
	{ label="Amy",             char1=Global.CHARACTERS.AMY,      char2=Global.CHARACTERS.NONE },
	{ label="Shadow",          char1=Global.CHARACTERS.SHADOW,   char2=Global.CHARACTERS.NONE },
]
var characterID = 0
# Used to toggle visibility of character sprites (initialized in `_ready()`)
var characterSprites = []

# level labels, the amount of labels in here determines the total amount of options, see set level option at the end for settings
var levelLabels = ["Base Zone Act 1", "Base Zone Act 2"]#, "Chunk Zone Act 1"]
# level id lines up with levelLabels
var levelID = 0

# Used to avoid repeated detection of inputs with analog stick
var lastInput: Vector2i = Vector2i.ZERO
# Used to avoid repeated ditection of inputs from buttons
var action_was_pressed_last_frame = false


func _ready():
	MusicController.reset_music_themes()
	MusicController.set_level_music(music)
	$UI/Labels/Control/Character.text = characters[characterID].label
	$UI/Labels/Control/MutliplayerMode.text = Global.MULTIMODE.find_key(Global.get_multimode())
	if nextZone != null:
		Global.nextZone = nextZone

	for child in $UI/Labels/CharacterOrigin.get_children():
		if child is Node2D or child is Sprite2D:
			characterSprites.append(child)
	assert(characters.size() == characterSprites.size())

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
			$UI/Labels/Control/Character.text = characters[characterID].label
			$Switch.play()
		if inputCue.y != lastInput.y and inputCue.y != 0:
			# `inputCue.y` is either 1 or -1, so `levelID+inputCue.y` will effectively
			# result in the previous/next level ID when the player presses up/down
			levelID = wrapi(levelID+inputCue.y,0,levelLabels.size())
			$UI/Labels/Control/Level.text = levelLabels[levelID]
			$Switch.play()
		#Save previous input for next read
		lastInput = inputCue
		
		# turn on and off visibility of the characters based on the current selection
		for i in characterSprites.size():
			characterSprites[i].visible = (characterID == i)
		
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
			# set player 2 to none to prevent redundant code
			Global.PlayerChar2 = Global.CHARACTERS.NONE
			
			# set the character
			Global.PlayerChar1 = characters[characterID].char1
			Global.PlayerChar2 = characters[characterID].char2
			
			# set the level
			match(levelID):
				0: # Base Zone Act 1
					Global.nextZone = load("res://Scene/Zones/BaseZone.tscn") # unnecessary since it's arleady set
				1: # Base Zone Act 2
					Global.nextZone = load("res://Scene/Zones/BaseZoneAct2.tscn") # Replace me! I don't exist yet!
				#2: # Chunk Zone Act 1
				#	Global.nextZone = load("res://Scene/Zones/ChunkZone.tscn")
			
			Global.main.change_scene_to_file(Global.nextZone,"FadeOut","FadeOut",1)
			
func change_multiplayer_mode():
	Global.cycle_multimode()
	$UI/Labels/Control/MutliplayerMode.text = Global.MULTIMODE.find_key(Global.get_multimode())
