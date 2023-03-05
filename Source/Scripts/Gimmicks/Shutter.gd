@tool
extends CharacterBody2D


@export var texture = preload("res://Graphics/Obstacles/Walls/shutter.png")
@export_enum("left","right","switch")var side = 0
var open = false

func _ready():
	if !Engine.is_editor_hint():
		# set areas
		$Mask.shape.size = Vector2(texture.get_width()/2,texture.get_height()/2)
		$OpenShutter/Mask.shape = $Mask.shape
		$CloseShutter/Mask.shape = $Mask.shape
		$CloseShutter2/Mask.shape = $Mask.shape
		
		$Shutter.texture = texture
		$OpenShutter.position.x = abs($OpenShutter.position.x)*(-1+(min(1,side)*2))
		$CloseShutter.position.x = abs($CloseShutter.position.x)*(-1+(min(1,side)*2))
		$CloseShutter2.position.x = abs($CloseShutter2.position.x)*(1-(min(1,side)*2))
		
		# disable areas if side is switch
		if side == 2:
			$OpenShutter.queue_free()
			$CloseShutter.queue_free()
			$CloseShutter2.queue_free()
		

func _process(delta):
	if !Engine.is_editor_hint():
		# move shutter
		$Shutter.position = $Shutter.position.move_toward(Vector2(0,-texture.get_height()*int(open)),delta*512)
		# disable mask if opened
		$Mask.disabled = open
	else:
		$Mask.shape.size = Vector2(texture.get_width()/2,texture.get_height()/2)
		$OpenShutter/Mask.shape = $Mask.shape
		$CloseShutter/Mask.shape = $Mask.shape
		$CloseShutter2/Mask.shape = $Mask.shape
		
		# hide masks if side is set to switch
		$OpenShutter/Mask.visible = int(side < 2)
		$CloseShutter/Mask.visible = int(side < 2)
		$CloseShutter2/Mask.visible = int(side < 2)
		
		$Shutter.texture = texture
		$OpenShutter.position.x = abs($OpenShutter.position.x)*(-1+(min(1,side)*2))
		$CloseShutter.position.x = abs($CloseShutter.position.x)*(-1+(min(1,side)*2))
		$CloseShutter2.position.x = abs($CloseShutter2.position.x)*(1-(min(1,side)*2))

# open on body touch (and player 1)
func _on_OpenShutter_body_entered(body):
	if body.playerControl == 1:
		open = true


# close on body leave (and player 1)
func _on_CloseShutter_body_entered(body):
	if body.playerControl == 1:
		open = false

# force open and force close is used for switches
func force_open():
	open = true

func force_close():
	open = false
