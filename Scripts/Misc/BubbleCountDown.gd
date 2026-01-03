extends AnimatedSprite2D

var screenOffset = null
var myPlayer = null
var countTime = 5
var forceFrame = 0.0

func _process(delta):
	# screen offset is used to try and track the screen, if it's not assigned then drift up
	if screenOffset == null:
		translate(Vector2(0,-32*delta))
		forceFrame += delta*30
		speed_scale = 2
	else:
		global_position = Global.players[0].get_camera().get_screen_center_position()+screenOffset


func _on_BubbleCountDown_animation_finished():
	# on first animation finish, set screen offset to current position, then play the bubble count
	# if already screen locked then free
	if screenOffset == null:
		var camera: PlayerCamera = Global.players[0].get_camera()
		speed_scale = 1.0
		play("count"+str(countTime))
		screenOffset = global_position-camera.get_screen_center_position()
		get_parent().remove_child(self)
		camera.add_child(self)
	else:
		queue_free()
