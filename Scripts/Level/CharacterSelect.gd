extends Node2D


@export var music = preload("res://Audio/Soundtrack/10. SWD_CharacterSelect.ogg")
@export var nextZone = load("res://Scene/Zones/BaseZone.tscn")
var selected = false

# character labels, the amount of labels in here determines the total amount of options, see the set character option at the end for settings
var characterLabels = ["Sonic and Tails", "Sonic", "Tails", "Knuckles", "Amy"]
# level labels, the amount of labels in here determines the total amount of options, see set level option at the end for settings
var levelLabels = ["Base Zone Act 1", "Base Zone Act 2"]#, "Chunk Zone Act 1"]
# character id lines up with characterLabels
var characterID = 0
# level id lines up with levelLabels
var levelID = 0
# Used to avoid repeated detection of inputs with analog stick
var lastInput = Vector2.ZERO


func _ready():
	Global.music.stream = music
	Global.music.play()
	$UI/Labels/Control/Character.text = characterLabels[characterID]
	if nextZone != null:
		Global.nextZone = nextZone

func _input(event):
	
	if !selected:
		var inputCue = Input.get_vector("gm_left","gm_right","gm_up","gm_down")
		inputCue.x = round(inputCue.x)
		inputCue.y = round(inputCue.y)
		if inputCue.x != lastInput.x:
			# select character rotation
			if inputCue.x < 0:
				characterID = wrapi(characterID-1,0,characterLabels.size())
			elif inputCue.x > 0:
				characterID = wrapi(characterID+1,0,characterLabels.size())
		if inputCue.y != lastInput.y:
			if inputCue.y > 0:
				levelID = wrapi(levelID+1,0,levelLabels.size())
			elif inputCue.y < 0:
				levelID = wrapi(levelID-1,0,levelLabels.size())
		#Save previous input for next read
		lastInput = inputCue
		
		$UI/Labels/Control/Character.text = characterLabels[characterID]
		$UI/Labels/Control/Level.text = levelLabels[levelID]
		
		# turn on and off visibility of the characters based on the current selection
		match(characterID):
			0: # Sonic and Tails
				$UI/Labels/CharacterOrigin/Sonic.visible = true
				$UI/Labels/CharacterOrigin/Tails.visible = true
				$UI/Labels/CharacterOrigin/Knuckles.visible = false
				$UI/Labels/CharacterOrigin/Amy.visible = false
			1: # Sonic
				$UI/Labels/CharacterOrigin/Sonic.visible = true
				$UI/Labels/CharacterOrigin/Tails.visible = false
				$UI/Labels/CharacterOrigin/Knuckles.visible = false
				$UI/Labels/CharacterOrigin/Amy.visible = false
			2: # Tails
				$UI/Labels/CharacterOrigin/Sonic.visible = false
				$UI/Labels/CharacterOrigin/Tails.visible = true
				$UI/Labels/CharacterOrigin/Knuckles.visible = false
				$UI/Labels/CharacterOrigin/Amy.visible = false
			3: # Knuckles
				$UI/Labels/CharacterOrigin/Sonic.visible = false
				$UI/Labels/CharacterOrigin/Tails.visible = false
				$UI/Labels/CharacterOrigin/Knuckles.visible = true
				$UI/Labels/CharacterOrigin/Amy.visible = false
			4: # Amy
				$UI/Labels/CharacterOrigin/Sonic.visible = false
				$UI/Labels/CharacterOrigin/Tails.visible = false
				$UI/Labels/CharacterOrigin/Knuckles.visible = false
				$UI/Labels/CharacterOrigin/Amy.visible = true
		
		# finish character select if start is pressed
		if event.is_action_pressed("gm_pause"):
			selected = true
			# set player 2 to none to prevent redundant code
			Global.PlayerChar2 = Global.CHARACTERS.NONE
			
			# set the character
			match(characterID):
				0: # Sonic and Tails
					Global.PlayerChar1 = Global.CHARACTERS.SONIC
					Global.PlayerChar2 = Global.CHARACTERS.TAILS
				1: # Sonic
					Global.PlayerChar1 = Global.CHARACTERS.SONIC
				2: # Tails
					Global.PlayerChar1 = Global.CHARACTERS.TAILS
				3: # Knuckles
					Global.PlayerChar1 = Global.CHARACTERS.KNUCKLES
				4: # Amy
					Global.PlayerChar1 = Global.CHARACTERS.AMY
					
			# set the level
			match(levelID):
				0: # Base Zone Act 1
					Global.nextZone = load("res://Scene/Zones/BaseZone.tscn") # unnecessary since it's arleady set
				1: # Base Zone Act 2
					Global.nextZone = load("res://Scene/Zones/BaseZoneAct2.tscn") # Replace me! I don't exist yet!
				#2: # Chunk Zone Act 1
				#	Global.nextZone = load("res://Scene/Zones/ChunkZone.tscn")
			
			Global.main.change_scene_to_file(Global.nextZone,"FadeOut","FadeOut",1)
