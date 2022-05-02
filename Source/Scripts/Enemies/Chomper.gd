extends EnemyBase

# Original Code Reference translated by VAdaPEGA
var animFrame = 0.0

func _ready():
	velocity.y = -7

func _physics_process(delta):
	velocity.y += 0.09375/delta
	position.y = min(position.y,0)
	
	if position.y >= 0:
		velocity.y = -7*60
	$VisibilityEnabler2D.position = -position

func _process(delta):
	if position.y > -192:
		if velocity.y > 0:
			# stationary
			animFrame = 0
		else:
			# slow animation
			animFrame += 4*delta
	else:
		# fast animation
		animFrame += 8*delta
	animFrame = fmod(animFrame,($Chomper.hframes*$Chomper.vframes))
	$Chomper.frame = floor(animFrame)
