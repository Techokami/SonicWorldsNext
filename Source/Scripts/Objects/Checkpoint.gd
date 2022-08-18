extends Area2D
var active = false
export var checkPointID = 0

func _ready():
	Global.checkPoints.append(self)
	if Global.currentCheckPoint == checkPointID:
		yield(get_tree(),"idle_frame")
		activate()


func activate():
	$Spinner.queue("flash")
	active = true
	Global.currentCheckPoint = checkPointID
	Global.checkPointTime = Global.levelTime
	
	for i in Global.checkPoints:
		if i.get("checkPointID") != null:
			if i.checkPointID < checkPointID:
				i.active = true
				i.get_node("Spinner").play("flash")

func _on_Checkpoint_body_entered(body):
	if !active:
		if body.playerControl == 1:
			$Spinner.play("spin")
			$Checkpoint.play()
			activate()
