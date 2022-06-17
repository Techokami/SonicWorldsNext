extends Area2D
tool

var screenSize = Vector2(320,224)

export var setLeft = true
export var leftBoundry  = 0
export var setTop = true
export var topBoundry  = 0

export var setRight = true
export var rightBoundry = 320
export var setBottom = true
export var bottomBoundry = 224

export var scrollSpeed = 0 # 0 will be instant


func _on_BoundrySetter_body_entered(body):
	# set boundry settings
	if (!Engine.editor_hint):
		# Check body has a camera variable
		if (body.get("camera") != null):
			# Check if set boundry is true, if it is then set the camera's boundries
			if (setLeft):
				body.limitLeft = max(leftBoundry,Global.hardBorderLeft)
			if (setTop):
				body.limitTop = max(topBoundry,Global.hardBorderTop)
			if (setRight):
				body.limitRight = min(rightBoundry,Global.hardBorderRight)
			if (setBottom):
				body.limitBottom = min(bottomBoundry,Global.hardBorderBottom)


func _process(delta):
	if (Engine.editor_hint):
		update()
		rightBoundry = max(leftBoundry+screenSize.x,rightBoundry)
		bottomBoundry = max(topBoundry+screenSize.y,bottomBoundry)

func _draw():
	if (Engine.editor_hint):
		# Left boundry
		draw_line((Vector2(leftBoundry,topBoundry)-global_position)*scale,(Vector2(leftBoundry,bottomBoundry)-global_position)*scale,Color.white)
		# Top boundry
		draw_line((Vector2(leftBoundry,topBoundry)-global_position)*scale,(Vector2(rightBoundry,topBoundry)-global_position)*scale,Color.white)
		# Right boundry
		draw_line((Vector2(rightBoundry,topBoundry)-global_position)*scale,(Vector2(rightBoundry,bottomBoundry)-global_position)*scale,Color.white)
		# Bottom boundry
		draw_line((Vector2(leftBoundry,bottomBoundry)-global_position)*scale,(Vector2(rightBoundry,bottomBoundry)-global_position)*scale,Color.white)
