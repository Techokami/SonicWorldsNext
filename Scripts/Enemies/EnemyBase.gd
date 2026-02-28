class_name EnemyBase extends CharacterBody2D

@export var damage_type: Global.HAZARDS = Global.HAZARDS.NORMAL
var playerHit = []

var Explosion = preload("res://Entities/Misc/BadnickSmoke.tscn")
var forceDamage = false
var defaultMovement = true

# We want to know about any collision objects so that we can turn them off when the enemy is killed
var collision_objects = []

signal destroyed

func _ready() -> void:
	# Check if the badnik was previously destroyed.
	if Global.nodeMemory.has(get_path()):
		queue_free()
		return
		
	collision_objects = find_children("*", "CollisionObject2D", true)

func _process(delta):
	# loop through players as i
	for i: PlayerChar in playerHit:
		# check if damage entity is on or supertime is bigger then 0
		if (i.get_collision_layer_value(20) or i.supTime > 0 or forceDamage):
			# Invoke player bounce checks and logic
			print("Invoking player bounce")
			i.player_bounce(self, PlayerChar.BOUNCE_MODES.NORMAL)
			# destroy
			Score.create(get_parent(), global_position, Global.SCORE_COMBO[min(Global.SCORE_COMBO.size()-1,i.enemyCounter)])
			i.enemyCounter += 1
			destroy()
			# cut the script short
			return false
		
		# if destroying the enemy fails and hit player exists then hit player
		# NOTE: Isn't hit_player always going to exist? We are talkign about PlayerChar objects only.
		if (i.has_method("hit_player")):
			i.hit_player(global_position,damage_type)
		
	# move
	if defaultMovement:
		translate(velocity*delta)

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

func destroy():
	#print("destroyed %s" % self)
	destroyed.emit()
	# create explosion
	var explosion = Explosion.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	# create animal
	Animal.create(get_parent(), global_position)
	# Remember I died. RIP.
	Global.nodeMemory.append(get_path())
	
	# We don't want to free the node... that's unnecessary and complicates some interactions that
	# revolve around collision.
	# free node
	#queue_free()
	
	# Turn off visibility of object
	visible = false
	set_process(false)
	set_physics_process(false)
	
	# Turn off collision layer/mask for the enemy itself
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	# Turn off collision for any Area2D within the enemy
	for area: CollisionObject2D in collision_objects:
		#print("disabling %s" % area)
		area.set_deferred("collision_layer", 0)
		area.set_deferred("collision_mask", 0)
