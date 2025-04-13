## EnemyProjectileBase objects and Hazards are pretty similar in concept. The
## main difference is that a bullet can be reflected (which in this case just
## means sent off in a direction based on the angle that it hit the player
## when the player is using one of the Sonic 3 shields). Aside from that it
## works almost exactly like the Hazard works. Character enters a collsion box,
## collision signals the body entered function, if the player is in the collision
## box while in the collision box and they lack a shield that defends against the
## projectile, they are considered 'hit' although whether or not that
## matters depends on whether the player is currently invincible. As long as they
## remain within the collision area though, the player will be considered hit on
## every frame that the player is in the collision which may give them an opprotunity
## to *become* vulnerable while inside the projectile.

class_name EnemyProjectileBase extends CharacterBody2D

## If this projectile has an element, that belongs here.
@export var damage_type: Global.HAZARDS = Global.HAZARDS.NORMAL
## If the projectile should be reflected by shields (other than the Sonic 1/2 shield), enable this
@export var can_be_reflected = true
var entities_hit = []

# This bullet has already been reflected (and should be considered harmless now)
var reflected = false

# Speed at which to reflect the bullet
var reflect_speed = 400

# 
var force_reflect

func _ready():
	$projectile.frame = 0

func _process(delta):
	for item in entities_hit:
		if item is PlayerChar and !reflected:
			var player : PlayerChar = item
			# if player shield is an elemental one then reflect
			if (player.get_shield() > 1 or force_reflect or item.reflective) and can_be_reflected:
				velocity = player.global_position.direction_to(global_position) * reflect_speed
				reflected = true
			else:
				player.hit_player(global_position, damage_type)
		else:
			# We don't currently allow enemies to hit things that aren't players, but if you
			# find the need for such things, add that logic in this else branch.
			pass
			
	# shift
	translate(velocity * delta)

## This usually indicates that a player has entered the damage collision for the bullet
func _on_body_entered(body):
	if !entities_hit.has(body):
		entities_hit.append(body)

## This usually indicates that a player has exited the damage collision for the bullet
func _on_body_exited(body):
	if entities_hit.has(body):
		entities_hit.erase(body)


func _on_DamageArea_area_entered(area):
	if area.get("parent") != null and area.get_collision_layer_value(20):
		if !entities_hit.has(area.parent):
			force_reflect = true
			entities_hit.append(area.parent)


## Clears a bullet from the simulation if it exits the visible area. Make sure
## to connect it to a VisibleOnScreenNotifier2D's screen_exited() signal.
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
