@tool
extends Area2D


@export_enum("left", "right") var boostDirection = 0
var dirMemory = boostDirection
@export var speed = 16

func _ready():
	# set direction
	$Booster.flip_h = bool(boostDirection)

func _process(_delta):
	if Engine.is_editor_hint():
		if (boostDirection != dirMemory):
			$Booster.flip_h = bool(boostDirection)
			dirMemory = boostDirection

func _on_SpeedBooster_body_entered(body: PlayerChar):
	# DO THE BOOST, WHOOOOOSH!!!!!!!
	body.movement.x = speed*(-1+(boostDirection*2))*60
	body.horizontalLockTimer = (15.0/60.0) # lock for 15 frames
	$sfxSpring.play()
	# exit out of state on certain states
	match(body.get_state()):
		PlayerChar.STATES.GLIDE: # DW's Note: Knuckles does *not* interact with these while gliding in Sonic 2.
			if !body.ground:
				body.get_avatar().get_animator().play("run")
				body.set_state(PlayerChar.STATES.AIR)
