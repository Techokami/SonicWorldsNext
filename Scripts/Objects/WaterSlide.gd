extends Area2D

var players = []
@export var speed = 400.0
@export var force = 5.0 # how fast to push the players velocity to speed

func _ready():
	visible = false

func _physics_process(delta):
	# if any players are found in the array, if they're on the ground make them roll
	for i: PlayerChar in players:
		if i.is_on_ground():
			# determine the direction of the arrow based on scale and rotation
			var getDir = sign(scale.rotated(rotation).x)
			var animator = i.get_avatar().get_animator()
			
			# if below speed, gradually force the movement to the speed value
			if (abs(i.movement.x) < getDir*speed or sign(i.movement.x) != getDir):
				i.movement.x = lerp(i.movement.x,getDir*speed,delta*force)
			else:
			# else just set movement
				i.movement.x = getDir*speed
			
			# force player direction
			if getDir != 0:
				i.direction = getDir
				# set flipping on sprite
				i.sprite.flip_h = (i.direction < 0)
			
			# force slide state
			if (i.get_state() != PlayerChar.STATES.ROLL or
					animator.current_animation != "slide"):
				i.set_state(i.STATES.ROLL)
				animator.play("slide")

func _on_ForceRoll_body_entered(body):
	if !players.has(body):
		players.append(body)


func _on_ForceRoll_body_exited(body):
	if players.has(body):
		body.set_state(body.STATES.NORMAL)
		players.erase(body)
