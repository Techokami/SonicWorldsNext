extends Area2D
tool

export (int, "left", "right") var boostDirection = 0
var dirMemory = boostDirection
export var speed = 16

func _ready():
	$Booster.flip_h = bool(boostDirection)

func _process(_delta):
	if Engine.editor_hint:
		if (boostDirection != dirMemory):
			$Booster.flip_h = bool(boostDirection)
			dirMemory = boostDirection

func _on_SpeedBooster_body_entered(body):
	body.movement.x = speed*(-1+(boostDirection*2))*60
	$sfxSpring.play()
	# exit out of state on certain states
	match(body.currentState):
		body.STATES.GLIDE:
			if !body.ground:
				body.animator.play("run")
				body.set_state(body.STATES.AIR)
