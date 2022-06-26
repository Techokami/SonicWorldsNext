extends Node2D
var scattered = false
var lifetime = 256/Global.originalFPS
var velocity = Vector2.ZERO
var player
var magnet = null
var ringacceleration = [0.75,0.1875]
var Particle = preload("res://Entities/Misc/GenericParticle.tscn")


func _process(delta):
	# scattered logic
	if (scattered):
		z_index = 7
		if (lifetime > 0):
			lifetime -= delta
		else:
			queue_free()
	if (player):
		if (player.ringDisTime <= 0 && (player.invTime*Global.originalFPS <= 90 || !scattered)):
			z_index = 1
			player.get_ring()
			var part = Particle.instance()
			get_parent().add_child(part)
			part.global_position = global_position
			part.play("RingSparkle")
			queue_free()

func _physics_process(delta):
	# scattered physics logic
	if (scattered):
		velocity.y += 0.09375*Global.originalFPS
		translate(velocity*delta)
		if ($FloorCheck.is_colliding() && velocity.y > 0):
			velocity.y *= -0.75
	elif (magnet):
		#relative positions
		var sx = sign(magnet.global_position.x - global_position.x)
		var sy = sign(magnet.global_position.y - global_position.y)
		
		#check relative movement
		var tx = int(sign(velocity.x) == sx)
		var ty = int(sign(velocity.y) == sy)
		
		#add to speed
		velocity.x += (ringacceleration[tx] * sx)/delta
		velocity.y += (ringacceleration[ty] * sy)/delta
		translate(velocity*delta)
		#"ringacceleration" would be an array, where: [0] = 0.75 [1] = 0.1875
		
		

func _on_Hitbox_body_entered(body):
	if (player != body):
		player = body


func _on_Hitbox_body_exited(body):
	if (player == body):
		player = null


func _on_Hitbox_area_shape_entered(area_id, area, area_shape, local_shape):
	if (magnet == null):
		magnet = area
