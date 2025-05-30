class_name Animal extends Node2D

enum ANIM_TYPE {FLAP,CHANGE_ON_FALL}
var anim_type: ANIM_TYPE = ANIM_TYPE.FLAP

enum ANIMAL_TYPE {BIRD,SQUIRREL,RABBIT,CHICKEN,PENGUIN,SEAL,PIG,EAGLE,MOUSE,MONKEY,TURTLE,BEAR}
@export var type: ANIMAL_TYPE = ANIMAL_TYPE.BIRD

var animal_data: Array[Dictionary] = [
# (Bird)
	{ position=Vector2(0,32),   anim_type=ANIM_TYPE.FLAP,           physics=Vector2(3.0,4.0) },
# (Squirrel)
	{ position=Vector2(72,32),  anim_type=ANIM_TYPE.CHANGE_ON_FALL, physics=Vector2(2.5,3.5) },
# (Rabbit)
	{ position=Vector2(0,96),   anim_type=ANIM_TYPE.CHANGE_ON_FALL, physics=Vector2(2.0,4.0) },
# (Chicken)
	{ position=Vector2(0,64),   anim_type=ANIM_TYPE.FLAP,           physics=Vector2(2.0,3.0) },
# (Penguin)
	{ position=Vector2(72,64),  anim_type=ANIM_TYPE.CHANGE_ON_FALL, physics=Vector2(1.5,3.0) },
# (Seal)
	{ position=Vector2(0,0),    anim_type=ANIM_TYPE.CHANGE_ON_FALL, physics=Vector2(1.25,1.5) },
# (Pig)
	{ position=Vector2(72,0),   anim_type=ANIM_TYPE.CHANGE_ON_FALL, physics=Vector2(1.75,3.0) },
# (Eagle)
	{ position=Vector2(72,160), anim_type=ANIM_TYPE.FLAP,           physics=Vector2(2.5,3.0) },
# (Mouse)
	{ position=Vector2(0,160),  anim_type=ANIM_TYPE.CHANGE_ON_FALL, physics=Vector2(2.0,3.0) },
# (Monkey)
	{ position=Vector2(72,128), anim_type=ANIM_TYPE.CHANGE_ON_FALL, physics=Vector2(2.75,3.0) },
# (Turtle)
	{ position=Vector2(72,96),  anim_type=ANIM_TYPE.CHANGE_ON_FALL, physics=Vector2(1.25,2.0) },
# (Bear)
	{ position=Vector2(0,128),  anim_type=ANIM_TYPE.CHANGE_ON_FALL, physics=Vector2(2.0,3.0) }
]

var animTime = 0
var bouncePower = 300
var velocity = Vector2(0,-4*60)
var speed = 180
var gravity = 0.21875
var forceDirection = true # set this to false for capsule logic
var active = true

## Creates an animal.
## [param parent] - parent object the animal will be attached to.[br]
## [param _global_position] - coordinates to create the animal at
##                            ([b]not[/b] relative to the [param parent]'s coordinates).[br]
## [param _active] - if [code]true[/code], the animal doesn't move (deactivated).[br]
## [param fixed_direction] - if [code]true[/code], the animal runs to the left (usual logic),
##                           otherwise it runs in a random direction (capsule logic).[br]
## [param _type] - type of the newly created animal.
static func create(parent: Node, _global_position: Vector2, _active: bool = true, fixed_direction: bool = true, _type: ANIMAL_TYPE = Global.animals[round(randf())]) -> Animal:
	var animal: Animal = preload("res://Entities/Misc/Animal.tscn").instantiate()
	animal.active = _active
	animal.forceDirection = fixed_direction
	animal.type = _type
	parent.add_child(animal)
	animal.global_position = _global_position
	return animal

func _ready():
	if forceDirection:
		scale.x = -scale.x
	else:
		scale.x = sign(scale.x)*(1-(round(randf())*2))
	$animals.region_rect.position = animal_data[type].position
	anim_type = animal_data[type].anim_type

func _physics_process(delta):
	# check if active, if not then stop processing physics
	if !active:
		return false
	# gravity
	velocity.y += gravity*60
	
	# move, ignore collission since we're only checking floors
	translate(velocity*delta)
	
	# if on floor and falling then bounce
	if ($FloorCheck.is_colliding() and velocity.y > 0):
		speed = animal_data[type].physics.x*60
		bouncePower = animal_data[type].physics.y*60
		
		if animal_data[type].anim_type == ANIM_TYPE.FLAP:
			gravity = 0.09375
		
		velocity.y = -bouncePower
		velocity.x = speed*scale.x



func _process(delta):
	# animation code
	if (velocity.x != 0):
		match (anim_type):
			ANIM_TYPE.FLAP:
				animTime += delta*30
				if (animTime >= 1):
					animTime = 0
					$animals.frame = wrapi($animals.frame+1,1,3)
			ANIM_TYPE.CHANGE_ON_FALL:
				if (velocity.y >= 0):
					$animals.frame = 2
				else:
					$animals.frame = 1


func _on_VisibilityNotifier2D_screen_exited():
	queue_free()

# set active on time out (some spawning scenerios like a capsule sets a delay)
func _on_ActivationTimer_timeout():
	active = true
