extends CharacterBody2D

# Sensors
var verticalSensorLeft = RayCast2D.new()
var verticalSensorRight = RayCast2D.new()
var horizontallSensor = RayCast2D.new()

var groundLookDistance = 14
@onready var pushRadius = $HitBox.shape.extents.x+1

func _ready():
	add_child(verticalSensorLeft)
	add_child(verticalSensorRight)
	add_child(horizontallSensor)
	update_sensors()

func update_sensors():
	verticalSensorLeft.position.x = -$HitBox.shape.extents.x
	verticalSensorLeft.target_position.y = ($HitBox.shape.extents.y+groundLookDistance)*(int(motion_velocity.y >= 0)-int(motion_velocity.y < 0))
	verticalSensorRight.position.x = -verticalSensorLeft.position.x
	verticalSensorRight.target_position.y = verticalSensorLeft.target_position.y
	horizontallSensor.target_position = Vector2(pushRadius*sign(motion_velocity.x),0)


func _physics_process(delta):
	motion_velocity = Vector2(-int(Input.is_action_pressed("ui_left"))+int(Input.is_action_pressed("ui_right")),-int(Input.is_action_pressed("ui_up"))+int(Input.is_action_pressed("ui_down")))*100
	
	move_and_slide()
	update_sensors()
	
	horizontallSensor.force_raycast_update()
	if horizontallSensor.is_colliding():
		translate(Vector2(horizontallSensor.get_collision_point().x-horizontallSensor.global_position.x-pushRadius*sign(horizontallSensor.target_position.x),0).rotated(rotation))
	
	var getFloor = get_nearest_vertical_sensor()
	if getFloor:
		translate((getFloor.get_collision_point()-getFloor.global_position+($HitBox.shape.extents*Vector2(0,-sign(getFloor.target_position.y)))))
	
	#getRoof.get_collision_point().round()-getRoof.global_position.round()+($HitBox.shape.extents*Vector2(0,1));
	#position += Vector2(getWall.get_collision_point().round().x-getWall.global_position.round().x-pushRadius*sign(getWall.cast_to.x),0).rotated(rotation);

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
