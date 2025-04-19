extends EnemyBase

const GRAVITY = 600
var direction = 1
var state = 0
var stateTimer = 0
var animTime = 0

var Particle = preload("res://Entities/Misc/GenericParticle.tscn")

func _ready():
	defaultMovement = false
	direction = -sign(scale.x)

func _physics_process(delta):
	# Direction checks
	$Motobug.scale.x = abs($Motobug.scale.x)*-direction
	$FloorCheck.position.x = abs($FloorCheck.position.x)*direction
	$FloorCheck.force_raycast_update()
	
	# Edge check
	if is_on_wall() or !$FloorCheck.is_colliding():
		state = 1
	
	# Movement
	if state == 0:
		velocity.x = direction*60
		animTime = fmod(animTime+delta*2,1)
		stateTimer = 0
	else: # Stationary
		velocity.x = 0
		animTime = 0
		stateTimer += delta
		
		# state timer check, if greater then 1 go back to normal
		if stateTimer >= 1:
			state = 0
			stateTimer = 0
			direction = -direction
	
	# Velocity movement
	set_velocity(velocity)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `Vector2.DOWN`
	set_up_direction(Vector2.UP)
	move_and_slide()
	velocity = velocity
	
	# Gravity
	if !is_on_floor():
		velocity.y += GRAVITY*delta
	
	# Set animation frame (tire swaps 5 times a second, in half a second (animTime is multiplied by 2), and drop arms when 0.2 seconds to the next number)
	$Motobug.frame = (floor(fmod(animTime*5,2))*2)+max(0,floor(animTime+0.2))
	
	# Moto bug smoke
	if fmod(animTime+delta*2,1) < animTime:
		var part = Particle.instantiate()
		get_parent().add_child(part)
		part.global_position = global_position-(Vector2(24,-2)*direction)
		part.play("MotoBugSmoke")
	
