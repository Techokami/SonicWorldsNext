extends Node



func calculate_input(event, action = "gm_action"):
	return int(event.is_action(action) || event.is_action_pressed(action))-int(event.is_action_released(action))


func getCurrentCamera2D():
	var viewport = get_viewport()
	if not viewport:
		return null
	var camerasGroupName = "__cameras_%d" % viewport.get_viewport_rid().get_id()
	var cameras = get_tree().get_nodes_in_group(camerasGroupName)
	for camera in cameras:
		if camera is Camera2D and camera.current:
			return camera
	return null

func div_by_delta(delta):
	return 0.016667*(0.016667/delta)
