extends Node



func calculate_input(event, action = "gm_action"):
	return int(event.is_action(action) || event.is_action_pressed(action))-int(event.is_action_released(action));
