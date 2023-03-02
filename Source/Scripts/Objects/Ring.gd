extends Node2D
var scattered = false
var lifetime = 256.0/60.0
var velocity = Vector2.ZERO
var player
var magnet = null
var magnetShape = null
var ringacceleration = [0.75,0.1875]
var Particle = preload("res://Entities/Misc/GenericParticle.tscn")


func _process(delta):
	# scattered logic
	if (scattered):
		z_index = 7
		$RingSprite.speed_scale = lifetime+1
		if (lifetime > 0):
			lifetime -= delta
		else:
			queue_free()
	if (player):
		# collect ring
		if (player.ringDisTime <= 0 and (player.invTime*60 <= 90 or scattered)):
			z_index = 1
			# get ring to player
			player.get_ring()
			var part = Particle.instantiate()
			get_parent().add_child(part)
			part.global_position = global_position
			part.play("RingSparkle")
			queue_free()

func _physics_process(delta):
	# scattered physics logic
	if (scattered):
		velocity.y += 0.09375*60.0
		translate(velocity*delta)
		if ($FloorCheck.is_colliding() and velocity.y > 0):
			velocity.y *= -0.75
	elif (magnet):
		#relative positions
		var sx = sign(magnet.global_position.x - global_position.x)
		var sy = sign(magnet.global_position.y - global_position.y)
		
		#check relative movement
		var tx = int(sign(velocity.x) == sx)
		var ty = int(sign(velocity.y) == sy)
		
		#add to speed
		velocity.x += (ringacceleration[tx] * sx)/GlobalFunctions.div_by_delta(delta)
		velocity.y += (ringacceleration[ty] * sy)/GlobalFunctions.div_by_delta(delta)
		translate(velocity*delta)
		if magnetShape.disabled:
			scattered = true
		#"ringacceleration" would be an array, where: [0] = 0.75 [1] = 0.1875
		
		

func _on_Hitbox_body_entered(body):
	if (player != body):
		player = body


func _on_Hitbox_body_exited(body):
	if (player == body):
		player = null


func _on_Hitbox_area_shape_entered(_area_id, area, _area_shape, _local_shape):
	if (magnet == null):
		magnet = area
		magnetShape = area.get_child(0)
