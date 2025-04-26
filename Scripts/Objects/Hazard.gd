## Hazards are objects (usually but not necessarily persistent) that when a player
## is interacting with due to overlapping will simply hurt the player.
class_name Hazard extends Area2D

## What element type is the hazard? Mostly useful for elemental shields.
@export var damage_type: Global.HAZARDS = Global.HAZARDS.NORMAL

# We need to maintain this list of players in the hazard because the player might
# enter while invincible or simply not exit before invincibility wears off.
var entities_hit = []

func _process(_delta):
	for item : Object in entities_hit:
		if item is PlayerChar:
			var player: PlayerChar = item
			player.hit_player(global_position, damage_type)
		else:
			# We currently don't process hazards on anything other than players. If you do, put
			# that logic in here.
			pass

func _on_body_entered(body):
	if (!entities_hit.has(body)):
		entities_hit.append(body)


func _on_body_exited(body):
	if (entities_hit.has(body)):
		entities_hit.erase(body)
