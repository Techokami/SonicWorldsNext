class_name PhysicsObject extends CharacterBody2D

# Sensors
var verticalObjectCheck = RayCast2D.new()
var verticalSensorLeft = RayCast2D.new()
var verticalSensorMiddle = RayCast2D.new() # mostly used for edge detection and clipping prevention
var verticalSensorMiddleEdge = RayCast2D.new() # used for far edge detection
var verticalSensorRight = RayCast2D.new()
var horizontalSensor = RayCast2D.new()
var slopeCheck = RayCast2D.new()
var objectCheck = RayCast2D.new()

@onready var sensorList = [verticalSensorLeft,verticalSensorMiddle,verticalSensorMiddleEdge,verticalSensorRight,horizontalSensor,slopeCheck]

var maxCharGroundHeight = 16 # this is to stop players getting stuck at the bottom of 16x16 tiles, 
# you may want to adjust this to match the height of your tile collisions
# this only works when on the floor
var yGroundDiff = 0 # used for y differences on ground sensors


var groundLookDistance = 14 # how far down to look
@onready var pushRadius = max(($HitBox.shape.size.x/2)+1,10) # original push radius is 10


# physics variables
var movement = velocity+Vector2(0.00001,0) # this is a band aid fix, physics objects have something triggered to make them work but it only happens when moving horizontally, so the solution for now is to have it add a unnoticeable amount of x movement
var ground = true
var roof = false
var moveStepLength = 8*60
# angle is the rotation based on the floor normal
var angle = 0
var gravityAngle = 0
# the collission layer, 0 for low, 1 for high
var collissionLayer = 0

# translate, (ignores physics)
var translate = false

# Vertical sensor reference
var getVert = null

signal disconectFloor
signal connectFloor
signal disconectCeiling
signal connectCeiling
signal positionChanged

func _ready():
	slopeCheck.modulate = Color.BLUE_VIOLET
	$HitBox.add_child(verticalSensorLeft)
	$HitBox.add_child(verticalSensorMiddle)
	$HitBox.add_child(verticalSensorMiddleEdge)
	$HitBox.add_child(verticalSensorRight)
	$HitBox.add_child(verticalObjectCheck)
	$HitBox.add_child(horizontalSensor)
	$HitBox.add_child(slopeCheck)
	$HitBox.add_child(objectCheck)
	#for i in sensorList:
	#	i.enabled = true
	update_sensors()
	# Object check only needs to be set once
	objectCheck.set_collision_mask_value(1,false)
	objectCheck.set_collision_mask_value(14,true)
	objectCheck.set_collision_mask_value(16,true)
	objectCheck.set_collision_mask_value(17,true)
	objectCheck.hit_from_inside = true
	verticalObjectCheck.set_collision_mask_value(1,false)
	verticalObjectCheck.set_collision_mask_value(14,true)
	#objectCheck.enabled = true
	#verticalObjectCheck.enabled = true
	# middle should also check for objects
	verticalSensorMiddle.set_collision_mask_value(14,true)
	verticalSensorMiddleEdge.set_collision_mask_value(14,true)
	verticalSensorMiddle.set_collision_mask_value(17,true)
	verticalSensorMiddleEdge.set_collision_mask_value(17,true)

func update_sensors():
	var rotationSnap = snapped(rotation,deg_to_rad(90))
	var shape = $HitBox.shape.size/2
	
	# floor sensors
	yGroundDiff = 0
	# calculate ground difference for smaller height masks
	if ground and shape.y <= maxCharGroundHeight:
		yGroundDiff = abs((shape.y)-(maxCharGroundHeight))
	
	# note: the 0.01 is to help just a little bit on priority for wall sensors
	verticalSensorLeft.position = Vector2(-(shape.x-0.01),-yGroundDiff)
	
	# calculate how far down to look if on the floor, the sensor extends more if the objects is moving, if the objects moving up then it's ignored,
	# if you want behaviour similar to sonic 1, replace "min(abs(movement.x/60)+4,groundLookDistance)" with "groundLookDistance"
	var extendFloorLook = min(abs(movement.x/60)+4,groundLookDistance)*(int(movement.y >= 0)*int(ground))
	
	verticalSensorLeft.target_position.y = ((shape.y+extendFloorLook)*(int(movement.y >= 0)-int(movement.y < 0)))+yGroundDiff
	
	
	verticalSensorRight.position = Vector2(-verticalSensorLeft.position.x,verticalSensorLeft.position.y)
	verticalSensorRight.target_position.y = verticalSensorLeft.target_position.y
	verticalSensorMiddle.target_position.y = verticalSensorLeft.target_position.y*1.1
	if movement.x != 0:
		verticalSensorMiddleEdge.position = (verticalSensorLeft.position*0.5*sign(movement.x))
	verticalSensorMiddleEdge.target_position.y = verticalSensorLeft.target_position.y*1.1
	
	
	# Object offsets, prevent clipping
	if !ground:
		# check left
		var offset = 0
		verticalObjectCheck.position.y = verticalSensorLeft.position.y
		# give a bit of distance for collissions
		verticalObjectCheck.target_position = Vector2(0,-(shape.y*0.25)+shape.y*-sign(verticalSensorLeft.target_position.y))
		
		# check left sensor
		verticalObjectCheck.position.x = verticalSensorLeft.position.x
		verticalObjectCheck.force_raycast_update()
		if verticalObjectCheck.is_colliding():
			# calculate the offset using the collission point and the cast positions
			offset = (verticalObjectCheck.get_collision_point()-(verticalObjectCheck.global_position+verticalObjectCheck.target_position)).y
		
		# check right sensor
		verticalObjectCheck.position.x = verticalSensorRight.position.x
		verticalObjectCheck.force_raycast_update()
		if verticalObjectCheck.is_colliding():
			# calculate the offset using the collission point and the cast positions,
			# compare it to the old offset, if it's larger then use new offset
			var newOffset = (verticalObjectCheck.get_collision_point()-(verticalObjectCheck.global_position+verticalObjectCheck.target_position)).y
			if abs(newOffset) > abs(offset):
				offset = newOffset
		
		# set the offsets for sensors
		if offset != 0:
			verticalSensorLeft.position.y = max(verticalSensorLeft.position.y,offset)
			verticalSensorRight.position.y = max(verticalSensorRight.position.y,offset)
		
	
	# wall sensor
	if sign(velocity.rotated(-rotationSnap).x) != 0:
		horizontalSensor.target_position = Vector2(pushRadius*sign(velocity.rotated(-rotationSnap).x),0)
	# if the player is on a completely flat surface then move the sensor down 8 pixels
	horizontalSensor.position.y = 8*int(round(rad_to_deg(angle)) == round(rad_to_deg(gravityAngle)) and ground)
	
	# slop sensor
	slopeCheck.position.y = shape.x
	slopeCheck.target_position = Vector2((shape.y+extendFloorLook)*sign(rotation-angle),0)
	
	
	verticalSensorLeft.global_rotation = rotationSnap
	verticalSensorRight.global_rotation = rotationSnap
	horizontalSensor.global_rotation = rotationSnap
	slopeCheck.global_rotation = rotationSnap
	
	# set collission mask values
	for i in sensorList:
		i.set_collision_mask_value(1,i.target_position.rotated(rotationSnap).y > 0)
		i.set_collision_mask_value(2,i.target_position.rotated(rotationSnap).x > 0)
		i.set_collision_mask_value(3,i.target_position.rotated(rotationSnap).x < 0)
		i.set_collision_mask_value(4,i.target_position.rotated(rotationSnap).y < 0)
		# reset layer masks
		i.set_collision_mask_value(5,false)
		i.set_collision_mask_value(6,false)
		i.set_collision_mask_value(7,false)
		i.set_collision_mask_value(8,false)
		i.set_collision_mask_value(9,false)
		i.set_collision_mask_value(10,false)
		i.set_collision_mask_value(11,false)
		i.set_collision_mask_value(12,false)
		
		# set layer masks
		i.set_collision_mask_value(1+((collissionLayer+1)*4),i.get_collision_mask_value(1))
		i.set_collision_mask_value(2+((collissionLayer+1)*4),i.get_collision_mask_value(2))
		i.set_collision_mask_value(3+((collissionLayer+1)*4),i.get_collision_mask_value(3))
		i.set_collision_mask_value(4+((collissionLayer+1)*4),i.get_collision_mask_value(4))
	
	
	horizontalSensor.force_raycast_update()
	verticalSensorLeft.force_raycast_update()
	verticalSensorRight.force_raycast_update()
	slopeCheck.force_raycast_update()
	


func _physics_process(delta):
	#movement += Vector2(-int(Input.is_action_pressed("gm_left"))+int(Input.is_action_pressed("gm_right")),-int(Input.is_action_pressed("gm_up"))+int(Input.is_action_pressed("gm_down")))*_delta*100
	var moveRemaining = movement # copy of the movement variable to cut down on until it hits 0
	var checkOverride = true
	while (!moveRemaining.is_equal_approx(Vector2.ZERO) or checkOverride) and !translate:
		checkOverride = false
		var moveCalc = moveRemaining.normalized()*min(moveStepLength,moveRemaining.length())
				
		velocity = moveCalc.rotated(angle)
		#set_velocity(velocity)
		# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `(Vector2.DOWN*3).rotated(gravityAngle)`
		set_up_direction(Vector2.UP.rotated(gravityAngle))
		move_and_slide()
		var _move = velocity
		update_sensors()
		var groundMemory = ground
		var roofMemory = roof
		ground = is_on_floor()
		roof = is_on_ceiling()
		
		
		# Wall sensors
		# Check if colliding
		if horizontalSensor.is_colliding():
			#  Calculate the move distance vectorm, then move
			var rayHitVec = (horizontalSensor.get_collision_point()-horizontalSensor.global_position)
			var normHitVec = -Vector2.LEFT.rotated(snap_angle(rayHitVec.normalized().angle()))
			position += (rayHitVec-(normHitVec*(pushRadius)))
		
		# Floor sensors
		getVert = get_nearest_vertical_sensor()
		# check if colliding (get_nearest_vertical_sensor returns false if no floor was detected)
		if getVert:
			# check if movement is going downward, if it is then run some ground routines
			if (movement.y >= 0):
				# ground routine
				# Set ground to true but only if movement.y is 0 or more
				ground = true
				# get ground angle
				angle = deg_to_rad(snapped(rad_to_deg(getVert.get_collision_normal().rotated(deg_to_rad(90)).angle()),0.001))
			else:
				# ceiling routine
				roof = true
			
			#  Calculate the move distance vectorm, then move
			var rayHitVec = (getVert.get_collision_point()-getVert.global_position)
			# Snap the Vector and normalize it
			var normHitVec = -Vector2.LEFT.rotated(snap_angle(rayHitVec.normalized().angle()))
			if move_and_collide(rayHitVec-(normHitVec*($HitBox.shape.size.y/2))-Vector2(0,yGroundDiff).rotated(rotation),true,true,true):
				var _col = move_and_collide(rayHitVec-(normHitVec*($HitBox.shape.size.y/2))-Vector2(0,yGroundDiff).rotated(rotation))
			else:
				# Do a check that we're not in the middle of a rotation, otherwise the player can get caught on outter curves (more noticable on higher physics frame rates)
				if snap_angle(angle) == snap_angle(rotation):
					position += (rayHitVec-(normHitVec*(($HitBox.shape.size.y/2)+0.25))-Vector2(0,yGroundDiff).rotated(rotation))
				else:
					# if the angle doesn't match the current rotation, move toward the slope angle unsnapped instead of following the raycast
					normHitVec = -Vector2.LEFT.rotated(rayHitVec.normalized().angle())
					position += (normHitVec-Vector2(0,yGroundDiff).rotated(rotation))
		
		# set rotation
		
		# slope check
		slopeCheck.force_raycast_update()
		
		if slopeCheck.is_colliding():
			var getSlope = snap_angle(slopeCheck.get_collision_normal().angle()+deg_to_rad(90))
			# compare slope to current angle, check that it's not going to result in our current angle if we rotated
			if getSlope != rotation:
				rotation = snap_angle(angle)
		else: #if no slope check then just rotate
			var preRotate = rotation
			rotation = snap_angle(angle)
			# verify if new angle would find ground
			if get_nearest_vertical_sensor() == null:
				rotation = preRotate
		
		# re check ground angle post shifting if on floor still
		if ground:
			getVert = get_nearest_vertical_sensor()
			if getVert:
				angle = deg_to_rad(snapped(rad_to_deg(getVert.get_collision_normal().rotated(deg_to_rad(90)).angle()),0.001))
		
		# Emit Signals
		if groundMemory != ground:
			# if on ground emit "connectFloor"
			if ground:
				emit_signal("connectFloor")
			# if no on ground emit "disconectFloor"
			else:
				emit_signal("disconectFloor")
				disconect_from_floor(true)
		if roofMemory != roof:
			# if on roof emit "connectCeiling"
			if roof:
				emit_signal("connectCeiling")
			# if no on roof emit "disconectCeiling"
			else:
				emit_signal("disconectCeiling")
		
		
		update_sensors()
		
		moveRemaining -= moveRemaining.normalized()*min(moveStepLength,moveRemaining.length())
		force_update_transform()
		
	if translate:
		position += (movement*delta)
	
	#Object checks
	
	if !translate:
		# temporarily reset mask and layer
		var layerMemory = collision_layer
		var maskMemory = collision_mask
		
		# move in place to make sure the player doesn't clip into objects
		set_collision_mask_value(17,true)
		var _col = move_and_collide(Vector2.ZERO)
		
		var dirList = [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]
		
		# loop through directions for collisions
		for i in dirList:
			objectCheck.clear_exceptions()
			match i:
				Vector2.DOWN:
					objectCheck.position = Vector2(-$HitBox.shape.size.x,$HitBox.shape.size.y)/2 +i
					objectCheck.target_position = Vector2($HitBox.shape.size.x,0)
				Vector2.UP:
					objectCheck.position = Vector2(-$HitBox.shape.size.x,-$HitBox.shape.size.y)/2 +i
					objectCheck.target_position = Vector2($HitBox.shape.size.x,0)
				Vector2.RIGHT:
					objectCheck.position = Vector2($HitBox.shape.size.x,-$HitBox.shape.size.y)/2 +i
					objectCheck.target_position = Vector2(0,$HitBox.shape.size.y)
				Vector2.LEFT:
					objectCheck.position = Vector2(-$HitBox.shape.size.x,-$HitBox.shape.size.y)/2 +i
					objectCheck.target_position = Vector2(0,$HitBox.shape.size.y)

			objectCheck.force_raycast_update()

			while objectCheck.is_colliding():
				if objectCheck.get_collider().has_method("physics_collision") and test_move(global_transform,i.rotated(angle).round()):
					objectCheck.get_collider().physics_collision(self,i.rotated(angle).round())
				# add exclusion, this loop will continue until there isn't any objects
				objectCheck.add_exception(objectCheck.get_collider())
				# update raycast
				objectCheck.force_raycast_update()
			
			
		# reload memory for layers
		collision_mask = maskMemory
		collision_layer = layerMemory
	emit_signal("positionChanged")
	

func snap_angle(angleSnap = 0.0):
	var wrapAngle = wrapf(angleSnap,deg_to_rad(0.0),deg_to_rad(360.0))

	if wrapAngle >= deg_to_rad(315.0) or wrapAngle <= deg_to_rad(45.0): # Floor
		return deg_to_rad(0.0)
	elif wrapAngle > deg_to_rad(45.0) and wrapAngle <= deg_to_rad(134.0): # Right Wall
		return deg_to_rad(90.0)
	elif wrapAngle > deg_to_rad(134.0) and wrapAngle <= deg_to_rad(225.0): # Ceiling
		return deg_to_rad(180.0)
	
	# Left Wall
	return deg_to_rad(270.0)
	

func get_nearest_vertical_sensor():
	verticalSensorLeft.force_raycast_update()
	verticalSensorRight.force_raycast_update()
	
	# check if one sensor is colliding and if the other isn't touching anything
	if verticalSensorLeft.is_colliding() and not verticalSensorRight.is_colliding():
		return verticalSensorLeft
	elif not verticalSensorLeft.is_colliding() and verticalSensorRight.is_colliding():
		return verticalSensorRight
	# if neither are colliding then return null (nothing), this way we can skip over collission checks
	elif not verticalSensorLeft.is_colliding() and not verticalSensorRight.is_colliding():
		return null
	
	# check if the left sensort is closer, else return the sensor on the right
	if verticalSensorLeft.get_collision_point().distance_to(global_position) <= verticalSensorRight.get_collision_point().distance_to(global_position):
		return verticalSensorLeft
	else:
		return verticalSensorRight

func disconect_from_floor(force = false):
	if ground or force:
		# convert velocity
		movement = movement.rotated(angle-gravityAngle)
		angle = gravityAngle
		ground = false
		if (snap_angle(rotation) != snap_angle(gravityAngle)):
			rotation = snap_angle(gravityAngle)

# checks and pushes the player out if a collision is detected vertically in either direction
func push_vertical():
	# set movement memory
	var movementMemory = movement
	var directions = [-1,1]
	# check directions
	for i in directions:
		movement.y = i
		update_sensors()
		getVert = get_nearest_vertical_sensor()
		if getVert:
			#  Calculate the move distance vectorm, then move
			var rayHitVec = (getVert.get_collision_point()-getVert.global_position)
			# Snap the Vector and normalize it
			var normHitVec = -Vector2.LEFT.rotated(snap_angle(rayHitVec.normalized().angle()))
			# shift
			position += (rayHitVec-(normHitVec*(($HitBox.shape.size.y/2)+0.25))-Vector2(0,yGroundDiff).rotated(rotation))
	# reset movement
	movement = movementMemory
