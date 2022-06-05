extends "res://Scripts/Player/State.gd"

# this is for respawning a second player
var targetPoint = Vector2.ZERO

func state_activated():
	targetPoint = parent.partner.global_position

func _process(delta):
	# Animation
	if parent.water:
		parent.animator.play("swim")
	else:
		parent.animator.play("fly")

func _physics_process(delta):
	parent.translate = true
	# slowly move the target point towards the player based on distance
	targetPoint = targetPoint.linear_interpolate(parent.partner.global_position,(targetPoint.distance_to(parent.partner.global_position)/32)*delta)
	# if player is a valid state, in range, on the 64th frame (or if player 2 mashes buttons) return to normal
	var goToNormal = (parent.global_position.distance_to(targetPoint) <= 64 and round(parent.global_position.y) == round(targetPoint.y)) and (
		parent.partner.currentState == parent.STATES.NORMAL or parent.partner.currentState == parent.STATES.AIR
		or parent.partner.currentState == parent.STATES.JUMP)
	
	if !goToNormal:
		parent.movement.y = 0
		# move to player y position
		parent.global_position.y = move_toward(parent.global_position.y,targetPoint.y,delta*60)
		
		var distance = targetPoint.x-parent.global_position.x
		# if far then fly by distance
		if distance < 192:
			#parent.movement.x += (distance/16)*delta*60
			parent.movement.x = (distance/16)*60
		else:
			parent.movement.x += 12*60*delta*sign(distance)
		# distance clamp
		if abs(distance)/16 > abs(parent.movement.x/60):
			parent.movement.x = (distance/16)*60
		
		if distance != 0:
			parent.direction = sign(distance)
		parent.sprite.flip_h = (parent.direction < 0)
	else:
		match(parent.partner.currentState):
			parent.STATES.NORMAL, parent.STATES.AIR, parent.STATES.JUMP:
				parent.groundSpeed = 0
				parent.animator.play("walk")
				parent.translate = false
				parent.collision_layer = parent.defaultLayer
				parent.collision_mask = parent.defaultMask
				parent.set_state(parent.STATES.NORMAL)
				parent.movement = Vector2.ZERO
				# copy limits to avoid out of bounds errors
				parent.limitLeft = parent.partner.limitLeft
				parent.limitRight = parent.partner.limitRight
				parent.limitTop = parent.partner.limitTop
				parent.limitBottom = parent.partner.limitBottom
