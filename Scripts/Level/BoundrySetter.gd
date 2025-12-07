@tool
extends Area2D

@onready var screenSize = get_viewport().get_visible_rect().size

@export var setLeft = true
@export var leftBoundry  = 0
@export var setTop = true
@export var topBoundry  = 0

@export var setRight = true
@export var rightBoundry = 320
@export var setBottom = true
@export var bottomBoundry = 224

@export var scrollSpeed = 0 # 0 will be instant


func _on_BoundrySetter_body_entered(body):
	# set boundry settings
	if (!Engine.is_editor_hint()):
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


func _process(_delta):
	if (Engine.is_editor_hint()):
		queue_redraw()
		# remember to change this for your game if the screen size gets changed, this is just for debugging
		screenSize = Vector2(320,224)
		rightBoundry = max(leftBoundry+screenSize.x,rightBoundry)
		bottomBoundry = max(topBoundry+screenSize.y,bottomBoundry)

func _draw():
	if (Engine.is_editor_hint()):
		# Left boundry
		draw_line((Vector2(leftBoundry,topBoundry)-global_position)*scale,(Vector2(leftBoundry,bottomBoundry)-global_position)*scale,Color.WHITE)
		# Top boundry
		draw_line((Vector2(leftBoundry,topBoundry)-global_position)*scale,(Vector2(rightBoundry,topBoundry)-global_position)*scale,Color.WHITE)
		# Right boundry
		draw_line((Vector2(rightBoundry,topBoundry)-global_position)*scale,(Vector2(rightBoundry,bottomBoundry)-global_position)*scale,Color.WHITE)
		# Bottom boundry
		draw_line((Vector2(leftBoundry,bottomBoundry)-global_position)*scale,(Vector2(rightBoundry,bottomBoundry)-global_position)*scale,Color.WHITE)
