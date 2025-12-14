extends Node2D
const MAX_LIFETIME = 256.0/60.0
var scattered = false
var lifetime = MAX_LIFETIME
var velocity = Vector2.ZERO
var player
var magnet = null
var magnetShape = null
var ringacceleration = [0.75,0.1875]
var value: int = 1
var Particle = preload("res://Entities/Misc/GenericParticle.tscn")

func _ready() -> void:
	if Global.nodeMemory.has(get_path()):
		queue_free()

func _process(delta):
	# scattered logic
	if (scattered):
		z_index = 7
		$RingSprite.speed_scale = lifetime / MAX_LIFETIME + 1
		if lifetime > 0.0:
			lifetime -= delta
			# make the ring blink at the end of its lifetime
			if lifetime <= 1.0:
				visible = !visible
		else:
			queue_free()
	if (player):
		# collect ring
		if (player.ringDisTime <= 0 and (player.invTime*60 <= 90 or scattered)):
			z_index = 1
			# get ring to player
			player.give_ring(value)
			if !scattered:
				# Mark as destroyed
				Global.nodeMemory.append(get_path())
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
		var pos_sign: Vector2 = (magnet.global_position-global_position).sign()
		
		#check relative movement
		var vel_sign: Vector2 = velocity.sign()
		
		#add to speed
		velocity += Vector2(
				ringacceleration[int(vel_sign.x == pos_sign.x)],
				ringacceleration[int(vel_sign.y == pos_sign.y)]
			) * pos_sign / GlobalFunctions.div_by_delta(delta)
		translate(velocity*delta)
		if magnetShape.disabled:
			scattered = true
		#"ringacceleration" would be an array, where: [0] = 0.75 [1] = 0.1875
		

func _on_Hitbox_body_entered(body):
	if (player != body):
		# The check below exists to prevent potential undesirable behavior where a partner
		# can immediatelly recollect all lost rings as soon as the leader is hurt.
		if (!scattered) or (scattered and lifetime < (3.3)):
			player = body


func _on_Hitbox_body_exited(body):
	if (player == body):
		player = null


func _on_Hitbox_area_shape_entered(_area_id, area, _area_shape, _local_shape):
	if (magnet == null):
		magnet = area
		magnetShape = area.get_child(0)
