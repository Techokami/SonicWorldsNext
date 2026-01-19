@tool
extends EnemyBase


@export var orbs = 4
@export var speed = -100
@export var moveSpeed = -10
@export var distance = 16
var spinOffset = 0
@export var classicOrbi = true

@onready var orbList = [get_node("Orb")]

func _ready():
	if !Engine.is_editor_hint():
		# Check if the badnik was previously destroyed.
		check_if_destroyed()
		# make frame use the correct Orbinaut design
		$orbinaut.frame = int(classicOrbi)*2
		$Orb/orb.frame = 1+int(classicOrbi)*2
		
		# initial velocity
		velocity.x = moveSpeed
		# set scale based on direction
		if moveSpeed != 0:
			scale.x = sign(-velocity.x)*abs(scale.x)
		
		# create duplicates of the surrounding orbs based on the total
		var orb: Hazard = $Orb
		for _i in range(orbs-1):
			var newOrb = orb.duplicate()
			add_child(newOrb)
			orbList.append(newOrb)

func _process(delta):
	if Engine.is_editor_hint():
		$orbinaut.frame = int(classicOrbi)*2
		$Orb/orb.frame = 1+int(classicOrbi)*2
		$Orb.position.y = -distance
	else:
		super(delta)

func _physics_process(delta):
	if !Engine.is_editor_hint():
		# classic behaviour (just rotate the orbs, don't touch initial velocity)
		if classicOrbi:
			spinOffset += speed*delta
			# rotate the orbs based on spinOffset
			var vec_right: Vector2 = Vector2(distance, 0.0)
			var degrees_per_orb: float = 360.0/orbs
			for i in orbs:
				orbList[i].position = vec_right.rotated(deg_to_rad(spinOffset+(degrees_per_orb*i)))
		# Launch base behaviour
		else:
			# check player exists
			if Global.players.size() > 0:
				var sprite: Sprite2D = $orbinaut
				var player = Global.players[0]
				
				# set scale based on direction
				var direction: float = signf(global_position.x-player.global_position.x)
				if direction != 0:
					sprite.scale.x = direction
				
				# do movement
				velocity.x = moveSpeed*sprite.scale.x if (player.movement.x != 0.0 and player.ground) else 0.0
				
				# update orb positions, but only if the player is on ground and moving
				# (velocity.x != 0.0), or if the orbs are at their initial position
				# (which means they were never updated since their creation)
				if velocity.x != 0.0 or orbList[0].position == orbList[1].position:
					spinOffset += speed*5*delta*signf(absf(velocity.x))*sprite.scale.x
					var vec_right: Vector2 = Vector2(distance, 0.0)
					var degrees_per_orb: float = 360.0/orbs
					for i in orbs:
						orbList[i].position = vec_right.rotated(deg_to_rad(spinOffset+(degrees_per_orb*i)))
