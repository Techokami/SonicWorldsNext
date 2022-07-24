tool
extends EnemyBase
# Thanks to VAdaPEGA for accuracy testing

var Projectile = preload("res://Entities/Enemies/Projectiles/BuzzBomberProjectile.tscn")

export(float,-180,180) var flyDirection = 0
export var travelDistance = 512
export var speed = 240
onready var origin = global_position
var side = -1

var editorOffset = 1

var isFiring = false
var fireTime = 0
var coolDown = 0

func _process(delta):
	if Engine.is_editor_hint():
		update()
		
		# move editor offset based on movement speed
		if editorOffset > -1:
			editorOffset -= (speed*delta/travelDistance)*2
		else:
			editorOffset = 1

func _physics_process(delta):
	if !Engine.is_editor_hint():
		# move if not firing
		if !isFiring:
			# move position toward origin point with the travel distance
			position = position.move_toward(origin+Vector2(travelDistance*side,0).rotated(deg2rad(flyDirection)),speed*delta)
			# if at the destination point then turn around
			if position.distance_to(origin+Vector2(travelDistance*side,0).rotated(deg2rad(flyDirection))) <= 1:
				$Sprite.scale.x = -$Sprite.scale.x
				side = -side
				# pause during turn
				$Sprite/Fire.visible = false
				isFiring = true
				$Timer.start(1)
				yield($Timer,"timeout")
				# resume movement
				isFiring = false
				$Sprite/Fire.visible = true
			else:
				calc_dir()
			# count down cool down
			if coolDown > 0:
				coolDown -= delta

func calc_dir():
	# calculate direction based on side movement and rotation
	var getDir = sign(Vector2(side,0).rotated(deg2rad(flyDirection)).x)
	# check that it's not 0 so it doesn't become invisible
	if getDir != 0:
		$Sprite.scale.x = -getDir
	
		

func _draw():
	if Engine.is_editor_hint():
		var sprite = $Sprite/BuzzBomber
		var size = Vector2(sprite.texture.get_width()/sprite.hframes,sprite.texture.get_height()/sprite.vframes)
		# first bomber pose
		draw_texture_rect_region(sprite.texture,
		Rect2(Vector2(travelDistance,0).rotated(deg2rad(flyDirection))-size/2,
		size)
		,Rect2(Vector2(0,0),
		size)
		,Color(1,1,1,0.5))
		
		# second bomber pose
		draw_texture_rect_region(sprite.texture,
		Rect2(Vector2(-travelDistance,0).rotated(deg2rad(flyDirection))-size/2,
		size)
		,Rect2(Vector2(0,0),
		size)
		,Color(1,1,1,0.5))
		
		# estimated movement
		draw_texture_rect_region(sprite.texture,
		Rect2(Vector2(travelDistance*clamp(editorOffset,-1,1),0).rotated(deg2rad(flyDirection))-size/2,
		size)
		,Rect2(Vector2(0,0),
		size)
		,Color(1,1,1,0.5))


func _on_PlayerCheck_body_entered(_body):
	if !isFiring and coolDown <= 0:
		isFiring = true
		$Sprite/Fire.visible = false
		
		# pause
		$Timer.start(0.25)
		yield($Timer,"timeout")
		
		# set sprites to 
		$Sprite/BuzzBomber.frame = 1
		$Sprite/Wings.play("fireWings")
		fireTime = 1
		
		# start firing timer
		$Timer.start(0.25)
		yield($Timer,"timeout")
		
		# fire projectile
		var fire = Projectile.instance()
		get_parent().add_child(fire)
		
		# set position with offset
		fire.global_position = global_position+Vector2(25*side,25)
		fire.scale.x = -side
		
		# create a weakref to verify projectile hasn't been deleted later
		var wrFire = weakref(fire)
		# wait for fire aniamtion to finish
		$Timer.start(16.0/60.0)
		yield($Timer,"timeout")
		# check that fire hasn't been deleted
		if wrFire.get_ref():
			# move projectile
			fire.get_node("projectile").play("fire")
			fire.velocity = Vector2(120*side,120)
		
		# last timer before returning to normal
		# account for how long the firing timer took
		$Timer.start(0.5-(16.0/60.0))
		yield($Timer,"timeout")
		# reset sprites and resume movement
		$Sprite/BuzzBomber.frame = 0
		$Sprite/Wings.play("wing")
		isFiring = false
		$Sprite/Fire.visible = true
		coolDown = 1 # add cooldown to prevent rapid fire
