@tool
extends EnemyBase


@onready var sprite = $Chomper

# Original Code RefCounted translated by VAdaPEGA
var animFrame = 0.0
var jump_height: float = -7.0

func _ready():
	if Engine.is_editor_hint():
		return
	# initial velocity
	jump_height = abs(get_parent().jump_height)
	sprite.texture = get_parent().sprite_image
	velocity.y = 0-jump_height
	set_physics_process(false)
	set_process(false)


func _physics_process(delta):
	if Engine.is_editor_hint():
		sprite.texture = get_parent().sprite_image
		return
	
	# gravity
	velocity.y += 0.09375/GlobalFunctions.div_by_delta(delta)
	position.y = min(position.y,0)
	
	# reset velocity
	if position.y >= 0:
		velocity.y = 0-jump_height*60

func _process(delta):
	if Engine.is_editor_hint():
		return
	super(delta)
	# animation states
	if position.y > -192:
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
