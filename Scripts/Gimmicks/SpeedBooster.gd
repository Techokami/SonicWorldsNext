@tool
extends Area2D


@export var boost_direction: Global.DIRECTIONS = Global.DIRECTIONS.RIGHT:
	set(value):
		boost_direction = value
		if is_node_ready():
			$Booster.flip_h = (boost_direction == Global.DIRECTIONS.RIGHT)

@export var speed = 16

func _ready():
	# set direction
	$Booster.flip_h = (boost_direction == Global.DIRECTIONS.RIGHT)

func _on_SpeedBooster_body_entered(body: PlayerChar):
	# DO THE BOOST, WHOOOOOSH!!!!!!!
	body.movement.x = speed * Global.DIRECTION_MULTIPLIERS[boost_direction] * 60.0
	body.set_horizontal_lock_timer(15.0/60.0) # lock for 15 frames
	body.set_direction(boost_direction)
	$sfxSpring.play()
	# exit out of state on certain states
	match(body.get_state()):
		PlayerChar.STATES.GLIDE: # DW's Note: Knuckles does *not* interact with these while gliding in Sonic 2.
			if !body.ground:
				body.get_avatar().get_animator().play("run")
				body.set_state(PlayerChar.STATES.AIR)
