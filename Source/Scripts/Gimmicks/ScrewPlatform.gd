extends Node2D
tool

export var top = 2
export var bottom = 2
export (int, "up", "down") var rightMovement = 0

var players = []
var activePlayers = []
var fall = false
var fallSpeed = 100

func _ready():
	scale.x = sign(1-(rightMovement*2))*abs(scale.x)
	$ScrewPipe.region_rect = Rect2($ScrewPipe.region_rect.position,Vector2($ScrewPipe.region_rect.size.x,(top*8)+(bottom*8)))
	$ScrewPipe.position = Vector2(0,(bottom*4)-(top*4))
	$ScrewBottom.position.y = (bottom*8)+4


func _process(delta):
	if Engine.editor_hint:
		scale.x = sign(1-(rightMovement*2))*abs(scale.x)
		$ScrewPipe.region_rect = Rect2($ScrewPipe.region_rect.position,Vector2($ScrewPipe.region_rect.size.x,(top*8)+(bottom*8)))
		$ScrewPipe.position = Vector2(0,(bottom*4)-(top*4))
		$ScrewBottom.position.y = (bottom*8)+4
func _physics_process(delta):
	if !Engine.editor_hint:
		# falling
		if fall:
			fallSpeed += 300*delta
			$Screw.position.y += fallSpeed*delta
			# stop processing
			return null
		
		for i in players:
			if sign(global_position.x-i.global_position.x) != sign(global_position.x-i.global_position.x+(i.velocity.x*delta)):
				if !activePlayers.has(i):
					activePlayers.append(i)
		for i in activePlayers:
			# movement power
			var goDirection = i.velocity.x*delta/4
			
			if ((!$Screw/FloorCheck.is_colliding() || goDirection > 0) && (!$Screw/CeilingCheck.is_colliding() || goDirection < 0)
			&& $Screw.position.y-goDirection > (-top*8)+12 && i.ground):
				i.position.y -= goDirection
				i.global_position.x = global_position.x
				$Screw/Screw.frame = posmod(floor(-$Screw.position.y/4),4)
			else:
				activePlayers.erase(i)
			$Screw.position.y -= goDirection
			$Screw.position.y = max($Screw.position.y,(-top*8)+12)
			if $Screw.position.y > bottom*8:
				fall = true
				$Screw/DeathTimer.start(1)

func _on_playerChecker_body_entered(body):
	if !players.has(body):
		players.append(body)


func _on_playerChecker_body_exited(body):
	if players.has(body):
		players.erase(body)
	if activePlayers.has(body):
		activePlayers.erase(body)


# prevent unnecessary run time processing for object
func _on_DeathTimer_timeout():
	fall = false
	$Screw.queue_free()
