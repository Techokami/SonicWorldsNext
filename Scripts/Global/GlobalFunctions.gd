## DEPRECATED, please use the functions of the same name in Global.gd from now on. This file may
## be removed at a later date.

extends Node

# returns an int, 0 = none, 1 = pressed, 2 = held (you'll most likely want to do > 0 if you're checking for pressed)
func calculate_input(event, action = "gm_action"):
	return int(event.is_action(action) or event.is_action_pressed(action))-int(event.is_action_released(action))

# get the current active camera
func getCurrentCamera2D():
	var viewport = get_viewport()
	if not viewport:
		return null
	var camerasGroupName = "__cameras_%d" % viewport.get_viewport_rid().get_id()
	var cameras = get_tree().get_nodes_in_group(camerasGroupName)
	for camera in cameras:
		if camera is Camera2D and camera.enabled:
			return camera
	return null

# the original game logic runs at 60 fps, this function is meant to be used to help calculate this,
# usually a division by the normal delta will cause the game to freak out at different FPS speeds
func div_by_delta(delta):
	return 0.016667*(0.016667/delta)

# get window size resolution as a vector2
func get_screen_size():
	return get_viewport().get_visible_rect().size
