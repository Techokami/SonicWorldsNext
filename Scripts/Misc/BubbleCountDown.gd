extends AnimatedSprite2D

var screenOffset = null
var myPlayer = null
var countTime = 5
var forceFrame = 0.0

func _ready():
	frame = 0

func _process(delta):
	# screen offset is used to try and track the screen, if it's not assigned then drift up
	if screenOffset == null:
		translate(Vector2(0,-32*delta))
		forceFrame += delta*30
		frame = int(floor(forceFrame))
	else:
		global_position = Global.players[0].camera.get_screen_center_position()+screenOffset


func _on_BubbleCountDown_animation_finished():
	# on first animation finish, set screen offset to current position, then play the bubble count
	# if already screen locked then free
	if screenOffset == null:
		play("count"+str(countTime))
		screenOffset = global_position-Global.players[0].camera.get_screen_center_position()
		get_parent().remove_child(self)
		Global.players[0].camera.add_child(self)
	else:
		queue_free()
