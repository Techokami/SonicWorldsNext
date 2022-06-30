extends Area2D

# playerID array and contact position
var players = []
var contactPoint = []

func _physics_process(delta):
	for i in players:
		i.movement = Vector2.ZERO
		i.animator.play("hang")


func _on_Hanger_body_entered(body):
	if !players.has(body):
		players.append(body)
		contactPoint.resize(players.size())
		contactPoint[players.size()-1] = null


func _on_Hanger_body_exited(body):
	if players.has(body):
		# remove player from contact point
		var getIndex = players.find(body)
		contactPoint.remove(getIndex)
		
		players.erase(body)
