extends PlayerState

# this is for respawning a second player
var targetPoint = Vector2.ZERO
var spawnTicker = (1.0/64.0)*60.0


func _ready():
	invulnerability = true # ironic


func state_activated():
	targetPoint = parent.partner.global_position


func state_process(_delta: float) -> void:
	# Animation
	if parent.water:
		parent.animator.play("swim")
	else:
		parent.animator.play("fly")


func state_physics_process(delta: float) -> void:
	parent.allowTranslate = true
	# slowly move the target point towards the player based on distance
	targetPoint = targetPoint.lerp(parent.partner.global_position,(targetPoint.distance_to(parent.partner.global_position)/32)*delta)
	
	# If player is in range or in a valid state, return to normal
	var is_close_to_target = parent.global_position.distance_to(targetPoint) <= 64
	var is_aligned_vertically = round(parent.global_position.y) == round(targetPoint.y)

	var is_partner_nearby = parent.global_position.distance_to(parent.partner.global_position) <= 16

	var partner_state = parent.partner.get_state()
	var is_partner_in_valid_state = (
		partner_state == parent.STATES.NORMAL or
		partner_state == parent.STATES.AIR or
		partner_state == parent.STATES.JUMP
	)

	var goToNormal = ((is_close_to_target and is_aligned_vertically) or is_partner_nearby) and \
		is_partner_in_valid_state
	
	var layerMemory = parent.collision_layer
	# set parent layer to collide with terrain
	parent.set_collision_layer_value(1,true)
	parent.set_collision_layer_value(2,true)
	parent.set_collision_layer_value(3,true)
	parent.set_collision_layer_value(4,true)
	
	# Do a test move to make sure we aren't inside an object, if not in a free location then just do fly logic
	if !goToNormal or parent.test_move(parent.global_transform,Vector2.ZERO):
		# restore layer
		parent.collision_layer = layerMemory
		
		parent.movement.y = 0
		# move to Sonic's Y position...
		parent.global_position.y = move_toward(parent.global_position.y,targetPoint.y,delta*60)
		if (Global.waterLevel != null):
			#Block Tails from going underwater in this state
			parent.global_position.y = min(parent.global_position.y,Global.waterLevel-16)
		else:
			#Block Tails from going out of bounds, in case Sonic is dead.
			parent.global_position.y = min(parent.global_position.y,parent.limitBottom-16)
		
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
	else: # Go back to normal
		# restore layer
		parent.collision_layer = layerMemory
		
		match(parent.partner.currentState):
			parent.STATES.NORMAL, parent.STATES.AIR, parent.STATES.JUMP:
				parent.groundSpeed = 0
				parent.animator.play("walk")
				parent.allowTranslate = false
				parent.collision_layer = parent.defaultLayer
				parent.collision_mask = parent.defaultMask
				parent.set_state(parent.STATES.AIR)
				parent.movement = Vector2.ZERO
				parent.collissionLayer = parent.partner.collissionLayer
				# copy limits to avoid out of bounds errors
				parent.limitLeft = parent.partner.limitLeft
				parent.limitRight = parent.partner.limitRight
				parent.limitTop = parent.partner.limitTop
				parent.limitBottom = parent.partner.limitBottom
