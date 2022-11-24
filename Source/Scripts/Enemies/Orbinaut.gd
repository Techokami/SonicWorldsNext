extends EnemyBase
tool

export var orbs = 4
export var speed = -100
export var moveSpeed = -10
export var distance = 16
var spinOffset = 0
export var classicOrbi = true

onready var orbList = [get_node("Orb")]

func _ready():
	if !Engine.is_editor_hint():
		# make frame use the correct Orbinaut design
		$orbinaut.frame = int(classicOrbi)*2
		$Orb/orb.frame = 1+int(classicOrbi)*2
		
		# initial velocity
		velocity.x = moveSpeed
		# set scale based on direction
		if moveSpeed != 0:
			scale.x = sign(-velocity.x)*abs(scale.x)
		
		# create duplicates of the surrounding orbs based on the total
		for _i in range(orbs-1):
			var newOrb = $Orb.duplicate()
			add_child(newOrb)
			orbList.append(newOrb)

func _process(_delta):
	if Engine.is_editor_hint():
		$orbinaut.frame = int(classicOrbi)*2
		$Orb/orb.frame = 1+int(classicOrbi)*2
		$Orb.position.y = -distance

func _physics_process(delta):
	if !Engine.is_editor_hint():
		# classic behaviour (just rotate the orbs, don't touch initial velocity)
		if classicOrbi:
			spinOffset += speed*delta
			# rotate the orbs based on spinOffset
			for i in range(orbList.size()):
				var getOrb = orbList[i]
				getOrb.position = (Vector2.RIGHT*distance).rotated(deg2rad(spinOffset+((360/orbs)*i)))
		# Launch base behaviour
		else:
			# check player exists
			if Global.players.size() > 0:
				var player = Global.players[0]
				
				# set scale based on direction
				if sign(global_position.x-player.global_position.x) != 0:
					$orbinaut.scale.x = sign(global_position.x-player.global_position.x)
				
				# do movement
				velocity.x = moveSpeed*$orbinaut.scale.x*abs(sign(player.movement.x*int(player.ground)))
				
				spinOffset += speed*5*delta*sign(abs(velocity.x))*$orbinaut.scale.x
				for i in range(orbList.size()):
					var getOrb = orbList[i]
					getOrb.position = (Vector2.RIGHT*distance).rotated(deg2rad(spinOffset+((360/orbs)*i)))
