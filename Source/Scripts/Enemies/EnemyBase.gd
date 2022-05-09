class_name EnemyBase extends KinematicBody2D

export var damageType = 0
var playerHit = []

var velocity = Vector2.ZERO
var Explosion = preload("res://Entities/Misc/BadnickSmoke.tscn")
var Animal = preload("res://Entities/Misc/Animal.tscn")


func _process(delta):
	if (playerHit.size() > 0):
		for i in playerHit:
			if (i.get_collision_layer_bit(19) || i.supTime > 0):
				if (i.movement.y < 0 || i.global_position.y > global_position.y):
					i.movement.y -= 60*sign(i.velocity.y)
				else:
					i.movement.y = -i.velocity.y
				Global.score(global_position,Global.SCORE_COMBO[min(Global.SCORE_COMBO.size()-1,i.enemyCounter)])
				i.enemyCounter += 1
				destroy()
				return false
			if (i.has_method("hit_player")):
				i.hit_player(global_position,damageType)
	translate(velocity*delta)

func _on_body_entered(body):
	if (!playerHit.has(body)):
		playerHit.append(body)


func _on_body_exited(body):
	if (playerHit.has(body)):
		playerHit.erase(body)

func _on_DamageArea_area_entered(area):
	if area.get("parent") != null and area.get_collision_layer_bit(19):
		if !playerHit.has(area.parent):
			playerHit.append(area.parent)

func destroy():
	var explosion = Explosion.instance()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	var animal = Animal.instance()
	get_parent().add_child(animal)
	animal.global_position = global_position
	queue_free()

func _on_InstaArea_area_entered(area):
	Global.score(global_position,Global.SCORE_COMBO[0])
	destroy()


