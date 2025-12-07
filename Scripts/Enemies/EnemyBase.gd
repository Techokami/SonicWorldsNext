class_name EnemyBase extends CharacterBody2D

@export_enum("Normal", "Fire", "Elec", "Water") var damageType = 0
var playerHit = []

var Explosion = preload("res://Entities/Misc/BadnickSmoke.tscn")
var Animal = preload("res://Entities/Misc/Animal.tscn")
var forceDamage = false
var defaultMovement = true

signal destroyed

func _ready() -> void:
	if Global.nodeMemory.has(self):
		queue_free()

func _process(delta):
	# checks if player hit has players inside
	if (playerHit.size() > 0):
		# loop through players as i
		for i in playerHit:
			# check if damage entity is on or supertime is bigger then 0
			if (i.get_collision_layer_value(20) or i.supTime > 0 or forceDamage):
				# check player is not on floor
				if !i.ground:
					if i.movement.y > 0 and i.global_position.y < global_position.y:
						# Inverse velocity is moving downward and hitting an enemy from above
						i.movement.y = -i.movement.y
					elif i.movement.y <= 0:
						# Push down very slightly is hitting an enmy moving upward
						i.movement.y += 100
					else:
						# If neither are true, just gain a little upward speed
						i.movement.y -= 100
					if i.shield == i.SHIELDS.BUBBLE:
							i.emit_enemy_bounce()
				# destroy
				Global.add_score(global_position,Global.SCORE_COMBO[min(Global.SCORE_COMBO.size()-1,i.enemyCounter)])
				i.enemyCounter += 1
				destroy()
				# cut the script short
				return false
			# if destroying the enemy fails and hit player exists then hit player
			if (i.has_method("hit_player")):
				i.hit_player(global_position,damageType)
	# move
	if defaultMovement:
		translate(velocity*delta)

func _on_body_entered(body):
	# add to player list
	if (!playerHit.has(body)):
		playerHit.append(body)


func _on_body_exited(body):
	# remove from player list
	if (playerHit.has(body)):
		playerHit.erase(body)

func _on_DamageArea_area_entered(area):
	# damage checking
	if area.get("parent") != null and area.get_collision_layer_value(20):
		if !playerHit.has(area.parent):
			forceDamage = true
			playerHit.append(area.parent)

func destroy():
	destroyed.emit()
	# create explosion
	var explosion = Explosion.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	# create animal
	var animal = Animal.instantiate()
	animal.animal = Global.animals[round(randf())]
	get_parent().add_child(animal)
	animal.global_position = global_position
	# free node
	queue_free()
