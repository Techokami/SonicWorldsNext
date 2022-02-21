class_name PhysicsObject extends CharacterBody2D

# Sensors
var verticalSensorLeft = RayCast2D.new()
var verticalSensorRight = RayCast2D.new()
var horizontallSensor = RayCast2D.new()
var slopeCheck = RayCast2D.new()

@onready var sensorList = [verticalSensorLeft,verticalSensorRight,horizontallSensor,slopeCheck]

var groundLookDistance = 14
@onready var pushRadius = $HitBox.shape.extents.x+1 # original push radius is 10

# physics variables
var movement = motion_velocity
var ground = true
var roof = false
var moveStepLength = 8*60
# angle is the rotation based on the floor normal
var angle = 0
var gravityAngle = 0
# the collission layer, 0 for low, 1 for high
var collissionLayer = 0

# Vertical sensor reference
var getVert = null

signal disconectFloor
signal connectFloor
signal disconectCeiling
signal connectCeiling

func _ready():
	add_child(verticalSensorLeft)
	add_child(verticalSensorRight)
	add_child(horizontallSensor)
	add_child(slopeCheck)
	update_sensors()

func update_sensors():
	var rotationSnap = snapped(rotation,deg2rad(90))
	
	# floor sensors
	verticalSensorLeft.position.x = -$HitBox.shape.extents.x
	
	# calculate how far down to look if on the floor, the sensor extends more if the objects is moving, if the objects moving up then it's ignored,
	# if you want behaviour similar to sonic 1, replace "min(abs(movement.x/60)+4,groundLookDistance)" with "groundLookDistance"
	var extendFloorLook = min(abs(movement.x/60)+4,groundLookDistance)*(int(movement.y >= 0)*int(ground))
	
	verticalSensorLeft.target_position.y = ($HitBox.shape.extents.y+extendFloorLook)*(int(movement.y >= 0)-int(movement.y < 0))
	verticalSensorRight.position.x = -verticalSensorLeft.position.x
	verticalSensorRight.target_position.y = verticalSensorLeft.target_position.y
	
	# wall sensor
	horizontallSensor.target_position = Vector2(pushRadius*sign(motion_velocity.rotated(-rotationSnap).x),0)
	# if the player is on a completely flat surface then move the sensor down 8 pixels
	horizontallSensor.position.y = 8*int(round(rad2deg(angle)) == round(rad2deg(gravityAngle)) && ground)
	
	# slop sensor
	slopeCheck.position.y = $HitBox.shape.extents.x
	slopeCheck.target_position = Vector2(($HitBox.shape.extents.y+extendFloorLook)*sign(rotation-angle),0)
	
	
	verticalSensorLeft.global_rotation = rotationSnap
	verticalSensorRight.global_rotation = rotationSnap
	horizontallSensor.global_rotation = rotationSnap
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
	
	horizontallSensor.force_raycast_update()
	verticalSensorLeft.force_raycast_update()
	verticalSensorRight.force_raycast_update()
	slopeCheck.force_raycast_update()
	

func _physics_process(_delta):
	#movement += Vector2(-int(Input.is_action_pressed("gm_left"))+int(Input.is_action_pressed("gm_right")),-int(Input.is_action_pressed("gm_up"))+int(Input.is_action_pressed("gm_down")))*_delta*100
	var moveRemaining = movement # copy of the movement variable to cut down on until it hits 0
	while !moveRemaining.is_equal_approx(Vector2.ZERO):
		
		var moveCalc = moveRemaining.normalized()*min(moveStepLength,moveRemaining.length())
		
		motion_velocity = moveCalc.rotated(angle)
		move_and_slide()
		update_sensors()
		var groundMemory = ground
		var roofMemory = roof
		ground = is_on_floor()
		roof = is_on_ceiling()
		
		# Wall sensors
		# Check if colliding
		if horizontallSensor.is_colliding():
			#  Calculate the move distance vectorm, then move
			var rayHitVec = (horizontallSensor.get_collision_point()-horizontallSensor.global_position)
			var normHitVec = -Vector2.LEFT.rotated(snap_angle(rayHitVec.normalized().angle()))
			translate(rayHitVec-(normHitVec*pushRadius))
		
		# Floor sensors
		getVert = get_nearest_vertical_sensor()
		# check if colliding (get_nearest_vertical_sensor returns false if no floor was detected)
		if getVert:
			# check if movement is going downward, if it is then run some ground routines
			if (movement.y >= 0):
				# ground routine
				# Set ground to true but only if movement is 0 or more
				ground = true
				# get ground angle
				angle = getVert.get_collision_normal().angle()+deg2rad(90)
			else:
				# ceiling routine
				roof = true
			
			#  Calculate the move distance vectorm, then move
			var rayHitVec = (getVert.get_collision_point()-getVert.global_position)
			# Snap the Vector and normalize it
			var normHitVec = -Vector2.LEFT.rotated(snap_angle(rayHitVec.normalized().angle()))
			if move_and_collide(rayHitVec-(normHitVec*$HitBox.shape.extents.y),true):
				move_and_collide(rayHitVec-(normHitVec*$HitBox.shape.extents.y))
			else:
				translate(rayHitVec-(normHitVec*$HitBox.shape.extents.y))
		
		# set rotation
		
		# slope check
		slopeCheck.force_raycast_update()
		if slopeCheck.is_colliding():
			var getSlope = snap_angle(slopeCheck.get_collision_normal().angle()+deg2rad(90))
			# compare slope to current angle, check that it's not going to result in our current angle if we rotated
			if getSlope != rotation:
				rotation = snap_angle(angle)
		else: #if no slope check then just rotate
			var preRotate = rotation
			rotation = snap_angle(angle)
			# verify if new angle would find ground
			if get_nearest_vertical_sensor() == null:
				rotation = preRotate
		
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
#		if previousRot != rotation:
#			# retest floor, if no floor then return to previous rotation
#			getFloor = get_nearest_vertical_sensor()
#			if !getFloor:
#				rotation = previousRot
		
		
		#rotation = snapped(angle,deg2rad(90))
		
		moveRemaining -= moveRemaining.normalized()*min(moveStepLength,moveRemaining.length())
	

func snap_angle(angleSnap = 0):
	var wrapAngle = wrapf(angleSnap,deg2rad(0),deg2rad(360))

	if wrapAngle >= deg2rad(315) or wrapAngle <= deg2rad(45): # Floor
		return deg2rad(0)
	elif wrapAngle > deg2rad(45) and wrapAngle <= deg2rad(134): # Right Wall
		return deg2rad(90)
	elif wrapAngle > deg2rad(134) and wrapAngle <= deg2rad(225): # Ceiling
		return deg2rad(180)
	
	# Left Wall
	return deg2rad(270)
	

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
		movement = movement.rotated(angle)
		angle = gravityAngle
		if (rotation != 0):
			rotation = 0
