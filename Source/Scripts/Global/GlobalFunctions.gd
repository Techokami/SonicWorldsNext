extends Node



func calculate_input(event, action = "gm_action"):
	return int(event.is_action("gm_action"))-int(event.is_action_released("gm_action"));
