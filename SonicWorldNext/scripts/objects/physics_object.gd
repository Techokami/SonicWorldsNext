extends CharacterBody2D

# Sensors
var verticalSensorLeft = RayCast2D.new()
var verticalSensorRight = RayCast2D.new()
var horizontallSensor = RayCast2D.new()

var groundLookDistance = 14
@onready var pushRadius = $HitBox.shape.extents.x+0.01 # Extra padding added to prevent floor sensors activating in walls

# physics variables
var movement = motion_velocity
var ground = true
var moveStepLength = 8*60
# angle is the rotation based on the floor normal
var angle = 0
var angleChangeBuffer = 0
var gravityAngle = 0


signal disconectFloor
signal connectFloor

func _ready():
	add_child(verticalSensorLeft)
	add_child(verticalSensorRight)
	add_child(horizontallSensor)
	update_sensors()

func update_sensors():
	var rotationSnap = snapped(rotation,deg2rad(90))
	verticalSensorLeft.position.x = -$HitBox.shape.extents.x
	verticalSensorLeft.target_position.y = ($HitBox.shape.extents.y+groundLookDistance)*(int(motion_velocity.rotated(-rotationSnap).round().y >= 0)-int(motion_velocity.rotated(-rotationSnap).round().y < 0))
	verticalSensorRight.position.x = -verticalSensorLeft.position.x
	verticalSensorRight.target_position.y = verticalSensorLeft.target_position.y
	horizontallSensor.target_position = Vector2(pushRadius*sign(motion_velocity.rotated(-rotationSnap).x),0)
	
	verticalSensorLeft.global_rotation = rotationSnap
	verticalSensorRight.global_rotation = rotationSnap
	horizontallSensor.global_rotation = rotationSnap
	


func _physics_process(delta):
	movement += Vector2(-int(Input.is_action_pressed("ui_left"))+int(Input.is_action_pressed("ui_right")),-int(Input.is_action_pressed("ui_up"))+int(Input.is_action_pressed("ui_down")))*100*delta
	
	var moveRemaining = movement
	
	while !moveRemaining.is_equal_approx(Vector2.ZERO):
		
		var moveCalc = moveRemaining.normalized()*min(moveStepLength,moveRemaining.length())
		
		motion_velocity = moveCalc.rotated(rotation)
		move_and_slide()
		update_sensors()
		var groundMemory = ground
		ground = is_on_floor()
		
		# Wall sensors
		horizontallSensor.force_raycast_update()
		# Check if colliding
		if horizontallSensor.is_colliding():
			#  Calculate the move distance vectorm, then move
			var rayHitVec = (horizontallSensor.get_collision_point()-horizontallSensor.global_position)
			translate(rayHitVec-(rayHitVec.sign()*pushRadius))
		
		# Floor sensors
		var getFloor = get_nearest_vertical_sensor()
		# check if colliding (get_nearest_vertical_sensor returns false if no floor was detected)
		if getFloor:
			# Set ground to true but only if movement is 0 or more
			ground = bool(movement.y >= 0)
			# get ground angle
			angle = getFloor.get_collision_normal().angle()+deg2rad(90)
			#  Calculate the move distance vectorm, then move
			var rayHitVec = (getFloor.get_collision_point()-getFloor.global_position)
			translate(rayHitVec-(rayHitVec.sign()*$HitBox.shape.extents.y))
		
		# if not on floor reset angle
		if !ground:
			angle = gravityAngle
		
		# Emit ground signals if ground has been changed
		if groundMemory != ground:
			# if on ground emit "connectFloor"
			if ground:
				emit_signal("connectFloor")
				print("CONNECT")
			# if no on ground emit "disconectFloor"
			else:
				emit_signal("disconectFloor")
				print("DISCONNECT")
		
		# set rotation
		rotation = snapped(angle,deg2rad(90))
		
		moveRemaining -= moveRemaining.normalized()*min(moveStepLength,moveRemaining.length())
	


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
