@tool
extends Node2D


@export var top = 2
@export var bottom = 2
enum DIRECTION { UP = 1, DOWN = -1 }
@export var right_movement: DIRECTION = DIRECTION.UP

var players = []
var playerPosX = []
var activePlayers = []
var fall = false
var fallSpeed = 100

func _ready():
	scale.x = float(right_movement)*abs(scale.x)
	$ScrewPipe.region_rect = Rect2($ScrewPipe.region_rect.position,Vector2($ScrewPipe.region_rect.size.x,(top*8)+(bottom*8)))
	$ScrewPipe.position = Vector2(0,(bottom*4)-(top*4))
	$ScrewBottom.position.y = (bottom*8)+4


func _process(_delta):
	if Engine.is_editor_hint():
		scale.x = float(right_movement)*abs(scale.x)
		$ScrewPipe.region_rect = Rect2($ScrewPipe.region_rect.position,Vector2($ScrewPipe.region_rect.size.x,(top*8)+(bottom*8)))
		$ScrewPipe.position = Vector2(0,(bottom*4)-(top*4))
		$ScrewBottom.position.y = (bottom*8)+4

func _physics_process(delta):
	if !Engine.is_editor_hint():
		# falling
		if fall:
			fallSpeed += 900*delta
			$Screw.position.y += fallSpeed*delta
			# stop processing
			return null
		
		# check if to lock player
		for i in players:
			# check if player position crossed the middle
			if sign(global_position.x-i.global_position.x) != sign(global_position.x-i.global_position.x+(i.movement.x*delta)) or (round(global_position.x-i.global_position.x)/4) == 0:
				if !activePlayers.has(i):
					activePlayers.append(i)
		
		# variable to calculate length of movement
		var moveOffset = 0
		
		for i in activePlayers:
			# movement power
			var goDirection = i.movement.x*delta/4
			
			if ((!$Screw/FloorCheck.is_colliding() or goDirection > 0) and (!$Screw/CeilingCheck.is_colliding() or goDirection < 0)
			and $Screw.position.y-goDirection > (-top*8)+12 and !fall and i.ground):
				i.global_position.x = global_position.x
				$Screw/Screw.frame = posmod(int(floor(-$Screw.position.y/4)),4)
			else:
				activePlayers.erase(i)
			
			# increase move offset by how fast hte player is moving
			moveOffset += -goDirection
		
		$Screw.position.y = max($Screw.position.y+moveOffset,(-top*8)+12)
		
		if $Screw.position.y > bottom * 8.0:
			fall = true
			$Screw/DeathTimer.start(5.0)

func _on_playerChecker_body_entered(body):
	if !players.has(body):
		players.append(body)


func _on_playerChecker_body_exited(body):
	players.erase(body)


# prevent unnecessary run time processing for object
func _on_DeathTimer_timeout():
	fall = false
	set_physics_process(false)
	$Screw.queue_free()
