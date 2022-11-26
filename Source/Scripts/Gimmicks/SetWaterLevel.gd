extends Area2D
tool

export var setWaterLevel = 0
export var setSpeed = 512

func _process(_delta):
	if Engine.editor_hint:
		update()

func _on_SetWaterLevel_body_entered(body):
	# check if entering player is player 1, then set water level
	if body.get("playerControl") != null:
		if body.playerControl == 1:
			Global.setWaterLevel = global_position.y+setWaterLevel
			Global.waterScrollSpeed = setSpeed

func _draw():
	# show what the water level is gonna be in the editor
	if Engine.editor_hint:
		draw_line(Vector2(-16,setWaterLevel)/scale,Vector2(16,setWaterLevel)/scale,Color(0,0,1,0.5),1+(1/abs(scale.y)))

