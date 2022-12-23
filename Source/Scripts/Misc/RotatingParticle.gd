extends AnimatedSprite
var time = 0
var direction = 1
var velocity = Vector2.ZERO
var getTarget = null


func _process(delta):
	# rotate
	position = position.rotated(deg2rad(360*delta)*direction)
	if getTarget != null:
		get_parent().global_position.move_toward(getTarget.global_position,delta)
	#translate(velocity*0.5*delta)
	time += delta
	if time > 0.3:
		queue_free()
