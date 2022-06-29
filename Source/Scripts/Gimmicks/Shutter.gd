extends KinematicBody2D
tool

export var texture = preload("res://Graphics/Obstacles/Walls/shutter.png")
export (int,"left","right")var side = 0
var open = false

func _ready():
	if !Engine.editor_hint:
		$Mask.shape.extents = Vector2(texture.get_width()/2,texture.get_height()/2)
		$OpenShutter/Mask.shape = $Mask.shape
		$CloseShutter/Mask.shape = $Mask.shape
		$CloseShutter2/Mask.shape = $Mask.shape
		
		$Shutter.texture = texture
		$OpenShutter.position.x = abs($OpenShutter.position.x)*(-1+(side*2))
		$CloseShutter.position.x = abs($CloseShutter.position.x)*(-1+(side*2))
		$CloseShutter2.position.x = abs($CloseShutter2.position.x)*(1-(side*2))

func _process(delta):
	if !Engine.editor_hint:
		# move shutter
		$Shutter.position = $Shutter.position.move_toward(Vector2(0,-texture.get_height()*int(open)),delta*512)
		$Mask.disabled = open
	else:
		$Mask.shape.extents = Vector2(texture.get_width()/2,texture.get_height()/2)
		$OpenShutter/Mask.shape = $Mask.shape
		$CloseShutter/Mask.shape = $Mask.shape
		$CloseShutter2/Mask.shape = $Mask.shape
		
		$Shutter.texture = texture
		$OpenShutter.position.x = abs($OpenShutter.position.x)*(-1+(side*2))
		$CloseShutter.position.x = abs($CloseShutter.position.x)*(-1+(side*2))
		$CloseShutter2.position.x = abs($CloseShutter2.position.x)*(1-(side*2))

func _on_OpenShutter_body_entered(body):
	if body.playerControl == 1:
		open = true


func _on_CloseShutter_body_entered(body):
	if body.playerControl == 1:
		open = false
