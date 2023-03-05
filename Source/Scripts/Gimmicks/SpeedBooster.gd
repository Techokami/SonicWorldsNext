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

func _on_SpeedBooster_body_entered(body):
	# DO THE BOOST, WHOOOOOSH!!!!!!!
	body.movement.x = speed*(-1+(boostDirection*2))*60
	$sfxSpring.play()
	# exit out of state on certain states
	match(body.currentState):
		body.STATES.GLIDE:
			if !body.ground:
				body.animator.play("run")
				body.set_state(body.STATES.AIR)
