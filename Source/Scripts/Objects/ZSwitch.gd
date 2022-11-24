extends Area2D



func _on_ZSwitch_body_entered(body):
	# set z index to match this area node of any body that enters here
	body.z_index = z_index
