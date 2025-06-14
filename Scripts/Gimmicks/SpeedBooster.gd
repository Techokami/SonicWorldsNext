@tool
extends Area2D


enum DIRECTION { LEFT, RIGHT }
@export var boostDirection: DIRECTION = DIRECTION.LEFT:
	set(value):
		boostDirection = value
		$Booster.flip_h = (boostDirection == DIRECTION.RIGHT)

@export var speed = 16

func _ready():
	# set direction
	$Booster.flip_h = (boostDirection == DIRECTION.RIGHT)

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
