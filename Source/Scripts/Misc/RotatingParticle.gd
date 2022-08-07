extends AnimatedSprite
var time = 0
var direction = 1
var velocity = Vector2.ZERO
#func _ready():
	#position = position.rotated(deg2rad(rand_range(0,360)))

func _process(delta):
	position = position.rotated(deg2rad(360*10*delta)*direction)
	translate(velocity*0.5*delta)
	time += delta
	if time > 0.3:
		queue_free()
