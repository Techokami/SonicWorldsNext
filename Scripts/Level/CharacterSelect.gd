extends Node2D


@export var music = preload("res://Audio/Soundtrack/10. SWD_CharacterSelect.ogg")
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

# character labels, the amount of labels in here determines the total amount of options, see the set character option at the end for settings
var characterLabels = ["Sonic and Tails", "Sonic", "Tails", "Knuckles", "Amy"]
# character id lines up with characterLabels
enum CHARACTER_ID { SONIC_AND_TAILS, SONIC, TAILS, KNUCKLES, AMY }
var characterID = CHARACTER_ID.SONIC_AND_TAILS
# level id lines up with levelLabels
var levelID = 0
# Used to toggle visibility of character sprites (initialized in `_ready()`)
var characterSprites = []
# Used to avoid repeated detection of inputs with analog stick
var lastInput = Vector2.ZERO


func _ready():
	Global.music.stream = music
	Global.music.play()
	$UI/Labels/Control/Character.text = characterLabels[characterID]

	for child in $UI/Labels/CharacterOrigin.get_children():
		if child is Node2D or child is Sprite2D:
			characterSprites.append(child)
	assert(characterLabels.size() == characterSprites.size())
	assert(characterLabels.size() == CHARACTER_ID.size())

func _input(event):
	
	if !selected:
		var inputCue = Input.get_vector("gm_left","gm_right","gm_up","gm_down")
		inputCue.x = round(inputCue.x)
		inputCue.y = round(inputCue.y)
		if inputCue.x != lastInput.x and inputCue.x != 0:
			# select character rotation
			if inputCue.x < 0:
				characterID = wrapi(characterID-1,0,characterLabels.size()) as CHARACTER_ID
			else: # inputCue.x > 0
				characterID = wrapi(characterID+1,0,characterLabels.size()) as CHARACTER_ID
			$Switch.play()
		if inputCue.y != lastInput.y and inputCue.y != 0:
			if inputCue.y > 0:
				levelID = wrapi(levelID+1,0,levelLabels.size())
			else: # inputCue.y < 0
				levelID = wrapi(levelID-1,0,levelLabels.size())
			$Switch.play()
		#Save previous input for next read
		lastInput = inputCue
		
		$UI/Labels/Control/Character.text = characterLabels[characterID]
		$UI/Labels/Control/Level.text = levelLabels[levelID]
		
		# turn on and off visibility of the characters based on the current selection
		for i in characterSprites.size():
			characterSprites[i].visible = (characterID == i)
		
		# finish character select if start is pressed
		if event.is_action_pressed("gm_pause"):
			selected = true
			# set player 2 to none to prevent redundant code
			Global.PlayerChar2 = Global.CHARACTERS.NONE
			
			# set the character
			match(characterID):
				CHARACTER_ID.SONIC_AND_TAILS:
					Global.PlayerChar1 = Global.CHARACTERS.SONIC
					Global.PlayerChar2 = Global.CHARACTERS.TAILS
				CHARACTER_ID.SONIC:
					Global.PlayerChar1 = Global.CHARACTERS.SONIC
				CHARACTER_ID.TAILS:
					Global.PlayerChar1 = Global.CHARACTERS.TAILS
				CHARACTER_ID.KNUCKLES:
					Global.PlayerChar1 = Global.CHARACTERS.KNUCKLES
				CHARACTER_ID.AMY:
					Global.PlayerChar1 = Global.CHARACTERS.AMY
			
			## Save the upcoming level reference for later use
			Global.nextZone = levelPaths[levelID]
			Global.currentZone = Global.nextZone
			Main.change_scene(Global.currentZone,"FadeOut",1.0,true)
