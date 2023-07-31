extends StaticBody2D

# Collision check
func physics_collision(body, hitVector):
	# check that the players hit direction is coming in from thet op
	if hitVector == Vector2.DOWN:
		# check that the colliding player is player 1
		if body == Global.players[0]:
			# run activation function
			get_parent().activateBeam()
