extends AnimatedSprite

var screenOffset = null
var myPlayer = null
var countTime = 5
var forceFrame = 0.0

func _ready():
	frame = 0

func _physics_process(delta):
	if screenOffset == null:
		translate(Vector2(0,-32*delta))
		forceFrame += delta*30
		frame = int(floor(forceFrame))
	else:
		global_position = Global.players[0].camera.get_camera_screen_center()+screenOffset


func _on_BubbleCountDown_animation_finished():
	if screenOffset == null:
		play("count"+str(countTime))
		screenOffset = global_position-Global.players[0].camera.get_camera_screen_center()
		get_parent().remove_child(self)
		Global.players[0].camera.add_child(self)
	else:
		queue_free()
