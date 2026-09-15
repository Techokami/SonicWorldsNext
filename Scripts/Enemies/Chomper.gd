@tool
extends EnemyBase

## The height for the Chomper to jump at the first time it comes onscreen.
## Mashers from Sonic 2 erroniously jump 1 unit lower the first time they load.
@export var first_jump_height: float = 7.0
## The height for the Chopper to jump at after the first time.
@export var jump_height: float = 7.0
## The sprite graphic to use.
@export var sprite_image: Texture2D = preload("res://Graphics/Enemies/chomper.png")

@onready var _initial_pos_y: float = position.y

# Original Code RefCounted translated by VAdaPEGA
var animFrame = 0.0

func _ready():
	if Engine.is_editor_hint():
		return
	# initial velocity
	jump_height = -jump_height
	$Chomper.texture = sprite_image
	velocity.y = -first_jump_height
	set_physics_process(false)
	set_process(false)

func _physics_process(delta):
	if Engine.is_editor_hint():
		$Chomper.texture = sprite_image
		return
	
	# gravity
	velocity.y += 0.09375/GlobalFunctions.div_by_delta(delta)
	position.y = minf(position.y, _initial_pos_y)
	
	# reset velocity
	if position.y >= _initial_pos_y:
		velocity.y = jump_height * 60.0

func _process(delta):
	if Engine.is_editor_hint():
		return
	super(delta)
	# animation states
	if position.y > _initial_pos_y - 192.0:
		if velocity.y > 0:
			# stationary
			animFrame = 0
		else:
			# slow animation
			animFrame += (60.0/8.0)*delta
	else:
		# fast animation
		animFrame += (60.0/4.0)*delta
	
	animFrame = fmod(animFrame,($Chomper.hframes*$Chomper.vframes))
	$Chomper.frame = floor(animFrame)


func _on_VisibilityEnabler2D_screen_entered():
	set_physics_process(true)
	set_process(true)


func _on_VisibilityEnabler2D_screen_exited():
	set_physics_process(false)
	set_process(false)
