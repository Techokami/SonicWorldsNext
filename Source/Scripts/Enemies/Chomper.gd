extends EnemyBase

# Original Code Reference translated by VAdaPEGA
var animFrame = 0.0

func _ready():
	velocity.y = -7
	set_physics_process(false)
	set_process(false)


func _physics_process(delta):
	velocity.y += 0.09375/GlobalFunctions.div_by_delta(delta)
	position.y = min(position.y,0)
	
	if position.y >= 0:
		velocity.y = -7*60

func _process(delta):
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
