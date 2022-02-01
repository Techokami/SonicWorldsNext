extends CharacterBody2D

# Sensors
var verticalSensorLeft = RayCast2D.new()
var verticalSensorRight = RayCast2D.new()
var horizontallSensor = RayCast2D.new()

var groundLookDistance = 14
@onready var pushRadius = $HitBox.shape.extents.x+1

var movement = motion_velocity

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
	movement = Vector2(-int(Input.is_action_pressed("ui_left"))+int(Input.is_action_pressed("ui_right")),-int(Input.is_action_pressed("ui_up"))+int(Input.is_action_pressed("ui_down"))).rotated(rotation)*100
	
	motion_velocity = movement
	move_and_slide()
	update_sensors()
	
	horizontallSensor.force_raycast_update()
	if horizontallSensor.is_colliding():
		var rayHitVec = (horizontallSensor.get_collision_point()-horizontallSensor.global_position)
		translate(rayHitVec-(rayHitVec.sign()*pushRadius))
	
	var getFloor = get_nearest_vertical_sensor()
	if getFloor:
		var rayHitVec = (getFloor.get_collision_point()-getFloor.global_position)
		translate(rayHitVec-(rayHitVec.sign()*$HitBox.shape.extents.y))
	

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
