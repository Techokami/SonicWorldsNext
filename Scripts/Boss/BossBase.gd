class_name BossBase extends CharacterBody2D

@export_enum("Normal", "Fire", "Elec", "Water") var damageType = 0
var playerHit = []

@export var hp = 8
var flashTimer = 0
var forceDamage = false
@export var hitTime = 32.0/60.0

signal got_hit
signal hit_player
signal flash_finished
signal defeated

# Note - depending on implementation, it could be appropriate to emit this signal from your boss implementation
# signal boss_over

var active = false


func _physics_process(delta):
	# flashing timer
	if flashTimer > 0:
		flashTimer -= delta
		if flashTimer <= 0:
			flash_finished.emit()
	# if not flashing do damage routine
	elif hp > 0 and active:
		# checks if player hit has players inside
		if playerHit.size() > 0:
			# loop through players as i
			for i: PlayerChar in playerHit:
				# check if damage entity is on or supertime is bigger then 0
				if (i.get_collision_layer_value(20) or i.supTime > 0 or forceDamage):
					i.movement = i.movement*-0.5
					# hit
					if hp > 0:
						$Hit.play()
						flashTimer = hitTime
						got_hit.emit()
						hp -= 1
						# check if gliding, if they are force them to fall
						
						if i.get_state() == PlayerChar.STATES.GLIDE:
							i.get_avatar().get_animator().play("glideFall")
							# reset player hitbox
							i.set_predefined_hitbox(PlayerChar.HITBOXES.NORMAL)
							i.reflective = false
							# XXX Modifying player state directly from another object seems a little odd to me
							i.get_state_object(PlayerChar.STATES.GLIDE).is_fall = true
					# check if dead
					if hp <= 0:
						defeated.emit()
				# if destroying the enemy fails and hit player exists then hit player
				elif (i.has_method("hit_player")):
					if i.hit_player(global_position,damageType):
						hit_player.emit()

func _on_body_entered(body):
	# add to player list
	if (!playerHit.has(body)):
		playerHit.append(body)


func _on_body_exited(body):
	# remove from player list
	playerHit.erase(body)


func _on_DamageArea_area_entered(area):
	# damage checking
	if area.get("parent") != null and area.get_collision_layer_value(20):
		if !playerHit.has(area.parent):
			forceDamage = true
			playerHit.append(area.parent)


func _on_HitBox_area_exited(area):
	# remove from damage area
	if area.get("parent") != null:
		playerHit.erase(area.parent)
