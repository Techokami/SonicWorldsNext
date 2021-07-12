extends KinematicBody2D


# Sensors
var floorCastLeft = RayCast2D.new();
var floorCastRight = RayCast2D.new();
var platCastLeft = RayCast2D.new();
var platCastRight = RayCast2D.new();


var roofCastLeft = RayCast2D.new();
var roofCastRight = RayCast2D.new();

var wallCastLeft = RayCast2D.new();
var wallCastRight = RayCast2D.new();

var castList = [floorCastLeft,floorCastRight,platCastLeft,platCastRight,
roofCastLeft,roofCastRight,wallCastLeft,wallCastRight];

# Physics variables
var velocity = Vector2.ZERO;
var ground = false;
var angle = Vector2.UP;
var canCollide = true;

# Adjustable/Lookup variables
onready var speedStepLimit = $PhysicsLookUp.speedStepLimit;
onready var groundLookDistance = $PhysicsLookUp.groundLookDistance;
onready var sonic2FloorSnap = $PhysicsLookUp.sonic2FloorSnap; # Use the sonic 2 and onward floor snapping check
onready var pushRadius = $HitBox.shape.extents.x+1;
export (int, "Low", "High") var defaultLayer = 0;


func _ready():
	add_child(floorCastLeft);
	add_child(floorCastRight);
	floorCastLeft.enabled = true;
	floorCastRight.enabled = true;
	floorCastLeft.set_collision_mask_bit(6,true);
	floorCastRight.set_collision_mask_bit(6,true);
	
	
	add_child(platCastLeft);
	add_child(platCastRight);
	platCastLeft.enabled = true;
	platCastRight.enabled = true;
	
	add_child(roofCastLeft);
	add_child(roofCastRight);
	roofCastLeft.enabled = true;
	roofCastRight.enabled = true;
	roofCastLeft.set_collision_mask_bit(2,true);
	roofCastRight.set_collision_mask_bit(2,true);
	roofCastLeft.set_collision_mask_bit(6,true);
	roofCastRight.set_collision_mask_bit(6,true);
	roofCastLeft.set_collision_mask_bit(0,false);
	roofCastRight.set_collision_mask_bit(0,false);
	
	add_child(wallCastLeft);
	add_child(wallCastRight);
	wallCastLeft.enabled = true;
	wallCastRight.enabled = true;
	wallCastLeft.set_collision_mask_bit(1,true);
	wallCastRight.set_collision_mask_bit(1,true);
	wallCastLeft.set_collision_mask_bit(6,true);
	wallCastRight.set_collision_mask_bit(6,true);
	wallCastLeft.set_collision_mask_bit(0,false);
	wallCastRight.set_collision_mask_bit(0,false);
	
	update_sensors();


# Use this to quickly update all the casts if the hitbox mask gets changed
func update_sensors():
	floorCastLeft.position.x = -$HitBox.shape.extents.x;
	floorCastLeft.cast_to.y = $HitBox.shape.extents.y+groundLookDistance;
	
	floorCastRight.position.x = -floorCastLeft.position.x;
	floorCastRight.cast_to.y = floorCastLeft.cast_to.y;
	
	platCastLeft.position = floorCastLeft.position;
	platCastLeft.cast_to.y = 5;
	platCastLeft.set_collision_mask_bit(0,true);
	#platCastLeft.set_collision_mask_bit(3,true);
	
	platCastRight.position = floorCastRight.position;
	platCastRight.cast_to.y = 5;
	platCastRight.collision_mask = platCastLeft.collision_mask;
	
	roofCastLeft.position.x = floorCastLeft.position.x;
	roofCastRight.position.x = floorCastRight.position.x;
	
	wallCastLeft.cast_to = Vector2(-pushRadius,0);
	wallCastRight.cast_to = Vector2(pushRadius,0);
	
func update_cast_to():
	if (!ground):
		floorCastLeft.cast_to.y = $HitBox.shape.extents.y;
		floorCastRight.cast_to.y = floorCastLeft.cast_to.y;
		roofCastLeft.cast_to.y = -floorCastLeft.cast_to.y;
		roofCastRight.cast_to.y = -floorCastLeft.cast_to.y;
		wallCastLeft.position.y = 0;
		wallCastRight.position.y = 0;
	else:
		roofCastLeft.cast_to.y = -$HitBox.shape.extents.y;
		roofCastRight.cast_to.y = roofCastLeft.cast_to.y;
		if (angle == Vector2.UP):
			wallCastLeft.position.y = 8;
			wallCastRight.position.y = 8;
		else:
			wallCastLeft.position.y = 0;
			wallCastRight.position.y = 0;
		floorCastLeft.cast_to.y = $HitBox.shape.extents.y+groundLookDistance;
		floorCastRight.cast_to.y = floorCastLeft.cast_to.y;


func _physics_process(delta):
	#if (Input.is_action_just_pressed("ui_end")):
		#print(move_and_collide(Vector2.RIGHT*16,true,true,true))
	var getFloor;# = get_closest_sensor(floorCastLeft,floorCastRight);
	var velocityInterp = velocity*delta;
	
	# sensor control
	update_cast_to();
	
	# Floor priority
	# check with the kinematic body if there's a floor below, if there is
	# set the floor to prioritise this collision
	var memLayer = collision_layer;
	collision_layer = 1;
	
	var floorPriority = (move_and_collide(velocityInterp.rotated(angle.rotated(deg2rad(90)).angle()),true,true,true));
	if (velocity.y <= 0):
		floorPriority = null;
	collision_layer = memLayer;
	
	if (!canCollide):
		velocityInterp = Vector2.ZERO;
		translate((velocity*delta).rotated(angle.rotated(deg2rad(90)).angle()));
		
	
	while (velocityInterp != Vector2.ZERO):
		
		var clampedVelocity = velocityInterp.clamped(speedStepLimit);
		
		#floorCastLeft.clear_exceptions();
		#floorCastRight.clear_exceptions();
		#platCastLeft.clear_exceptions();
		#platCastRight.clear_exceptions();
		
		clear_all_exceptions();
		
		# move the object
		translate(clampedVelocity.rotated(angle.rotated(deg2rad(90)).angle()));
		#move_and_collide(clampedVelocity.rotated(angle.rotated(deg2rad(90)).angle()));
		
		
		# Floor priority back up check, if there's no floor ahead, check below
		if (!floorPriority && velocity.y >= 0):
			collision_layer = 1;
			floorPriority = move_and_collide(Vector2.DOWN.rotated(rotation)*8,true,true,true);
			collision_layer = memLayer;
		
		
		
		exclude_layers();
		
		# platforms
		platCastLeft.force_raycast_update();
		platCastRight.force_raycast_update();
		
		
#		if (ground):
#			if (floorPriority):
#				# left floor priority
#				while (floorCastLeft.is_colliding()):
#					floorCastLeft.add_exception(floorCastLeft.get_collider());
#					floorCastLeft.force_raycast_update();
#
#				floorCastLeft.remove_exception(floorPriority.collider);
#				floorCastLeft.force_raycast_update();
#				if (!floorCastLeft.is_colliding()):
#					floorCastLeft.clear_exceptions();
#
#				# right floor priority
#				while (floorCastRight.is_colliding()):
#					floorCastRight.add_exception(floorCastRight.get_collider());
#					floorCastRight.force_raycast_update();
#
#				floorCastRight.remove_exception(floorPriority.collider);
#				floorCastRight.force_raycast_update();
#				if (!floorCastRight.is_colliding()):
#					floorCastRight.clear_exceptions();
#
#
#			while (platCastLeft.is_colliding()):
#				floorCastLeft.add_exception(platCastLeft.get_collider());
#				floorCastRight.add_exception(platCastLeft.get_collider());
#				platCastLeft.add_exception(platCastLeft.get_collider());
#				platCastRight.add_exception(platCastLeft.get_collider());
#				platCastLeft.force_raycast_update();
#
#
#			while (platCastRight.is_colliding()):
#				floorCastRight.add_exception(platCastRight.get_collider());
#				floorCastLeft.add_exception(platCastRight.get_collider());
#				platCastRight.add_exception(platCastRight.get_collider());
#				platCastLeft.add_exception(platCastRight.get_collider());
#				platCastRight.force_raycast_update();
#
#		exclude_layers();
		
		# Wall code
		
		var getWall = get_closest_sensor(wallCastLeft,wallCastRight);
		
		
		if (getWall):
			position += Vector2(getWall.get_collision_point().x-getWall.global_position.x-pushRadius*sign(getWall.cast_to.x),0).rotated(rotation);
			touch_wall(getWall);
		
		
		velocityInterp -= clampedVelocity;
		
		force_update_transform();
		
		getFloor = get_closest_sensor(floorCastLeft,floorCastRight);
		var priorityAngle = get_floor_collision(getFloor)
		
		# Set sonic 2 floor snap to false to restore snapping to sonic 1 floor snap logic
		var s2Check = true;
		if (sonic2FloorSnap && getFloor):
			s2Check = ((getFloor.get_collision_point()-getFloor.global_position-
			($HitBox.shape.extents*Vector2(0,1)).rotated(rotation)).y <=
			min(abs(velocity.x/60)+4,groundLookDistance));
		
		if (getFloor && round(velocity.y) >= 0 && s2Check):
			position += getFloor.get_collision_point()-getFloor.global_position-($HitBox.shape.extents*Vector2(0,1)).rotated(rotation);
			
			
			var snapped = (snap_rotation(-rad2deg(priorityAngle)-90));
			
			# check if angle gets changed
			if (rotation != snapped.angle()):
				# get the current rotation
				var lastRotation = rotation;
				var lastAngle = priorityAngle;
				# do the snap
				rotation = snapped.angle();
				#update_raycasts();
				
				var lastFloor;
				# verify new angle won't make the player snap back the next frame
				# for the original rotation method comment this next part out
				if getFloor == floorCastLeft:
					lastFloor = floorCastLeft;
				elif getFloor == floorCastRight:
					lastFloor = floorCastRight;
				
				getFloor = get_closest_sensor(floorCastLeft,floorCastRight);
				
				priorityAngle = get_floor_collision(getFloor)
				
				# check new rotation
				if (getFloor):
					if (snapped != (snap_rotation(-rad2deg(priorityAngle)-90))):
						rotation = lastRotation;
						priorityAngle = lastAngle;
						
				else:
					getFloor = lastFloor;
					rotation = lastRotation;
					priorityAngle = lastAngle;
#					getFloor.force_raycast_update()
#					priorityAngle = get_floor_collision(getFloor)
			
			
			
			
			#$icon.rotation = getFloor.get_collision_normal().angle()+deg2rad(90)-rotation;
			
			#angle = getFloor.get_collision_normal();
			angle = Vector2.RIGHT.rotated(priorityAngle);
			
			connect_to_floor();
			if (getFloor.get_collider() != null):
				touch_floor(getFloor);
	
		else:
			disconect_from_floor();
			if (velocity.y < 0):
				var getRoof = get_closest_sensor(roofCastLeft,roofCastRight);
				if (getRoof):
					if (!touch_ceiling(getRoof)):
						position += getRoof.get_collision_point()-getRoof.global_position+($HitBox.shape.extents*Vector2(0,1));
		
	#update();

func get_floor_collision(getFloor):
	var priorityPoint = null;
	var priorityAngle = rotation;
	if (getFloor):
		priorityPoint = getFloor.get_collision_point();
		priorityAngle = getFloor.get_collision_normal().angle();
		
		var getCast = getFloor.cast_to.rotated(getFloor.global_rotation);
		var floorTile = null;
			
		if (getFloor.get_collider().has_method("get_surface_point")):
			floorTile = getFloor.get_collider().get_surface_point(getFloor.global_position.round(),
			getCast.length()*sign(getCast.x+getCast.y),
			(abs(getCast.x) > abs(getCast.y)));
		if (floorTile != null):
			priorityAngle = getFloor.get_collider().get_angle(floorTile,Vector2.UP.rotated(rotation))+deg2rad(-90);
	
	return priorityAngle

func get_closest_sensor(firstRaycast,secondRaycast):
	var leftFloor = null;
	var rightFloor = null;
	
	var prevPose = [firstRaycast.global_position,secondRaycast.global_position];
	
#	firstRaycast.global_position = firstRaycast.global_position.round();
#	secondRaycast.global_position = secondRaycast.global_position.round();
	
	firstRaycast.force_update_transform();
	secondRaycast.force_update_transform();
	firstRaycast.force_raycast_update();
	secondRaycast.force_raycast_update();
	
	if (firstRaycast.is_colliding()):
		leftFloor = firstRaycast;
	if (secondRaycast.is_colliding()):
		rightFloor = secondRaycast;
	
	firstRaycast.global_position = prevPose[0];
	secondRaycast.global_position = prevPose[1];
	
	if (leftFloor == null || rightFloor == null):
		if (leftFloor != null):
			return leftFloor;
		elif (rightFloor != null):
			return rightFloor;
		return null;
	
	
	if ((leftFloor.global_position-leftFloor.get_collision_point()).length() <
	(rightFloor.global_position-rightFloor.get_collision_point()).length()):
		return leftFloor;
	return rightFloor;
	
	
	
	if ((firstRaycast.global_position-leftFloor).length() <
	(rightFloor.global_position-rightFloor).length()):
		return leftFloor;
	return rightFloor;



func snap_rotation(getAngle):
	getAngle = round(getAngle);
	getAngle = wrapf(getAngle,0,360);
	#if (angle < 0):
	#	angle += 360;
	
	#Floor
	if (getAngle <= 45 || getAngle >= 315):
		return Vector2.RIGHT;
	#Right Wall
	elif (getAngle >= 46 && getAngle <= 134):
		return Vector2.UP;
	#Ceiling
	elif (getAngle >= 135 && getAngle <= 225):
		return Vector2.LEFT;
	#Left Wall
	elif (getAngle >= 226 && getAngle <= 314):
		return Vector2.DOWN;

func exclude_layers():
	for i in castList:
		i.force_raycast_update();
		quick_exclude_check(i);

func quick_exclude_check(rayCast):
	if (rayCast.is_colliding()):
		if (rayCast.get_collider().get_collision_mask_bit(4-defaultLayer)):
			for i in castList:
				i.add_exception(rayCast.get_collider());

func clear_all_exceptions():
	for i in castList:
		i.clear_exceptions();
	for i in get_collision_exceptions():
		remove_collision_exception_with(i);

func update_raycasts():
	for i in castList:
		i.force_raycast_update();
	


func disconect_from_floor():
	if ground:
		# convert velocity
		velocity = velocity.rotated(-angle.angle_to(Vector2.UP));
		angle = Vector2.UP;
		ground = false;
		if (rotation != 0):
			rotation = 0;

func connect_to_floor():
	if (!ground):
		ground = true;

func touch_floor(caster):
	if (caster.get_collider().has_method("physics_floor_override")):
		caster.get_collider().physics_floor_override(self,caster);

func touch_ceiling(caster):
	if (caster.get_collider().has_method("physics_ceiling_override")):
		return caster.get_collider().physics_ceiling_override(self,caster);
	else:
		var getAngle = -rad2deg(caster.get_collision_normal().angle())-90+360;
		if (getAngle > 225 || getAngle < 135):
			rotation = snap_rotation(-rad2deg(caster.get_collision_normal().angle())-90).angle();
			#position += caster.get_collision_point()-caster.global_position-($HitBox.shape.extents*Vector2(0,1)).rotated(rotation);
			velocity = Vector2(velocity.y*-sign(sin(deg2rad(getAngle))),0);
			connect_to_floor();
			return true;
		else:
			velocity.y = 0;
		return false;

func touch_wall(caster):
	if (caster.get_collider().has_method("physics_wall_override")):
		caster.get_collider().physics_wall_override(self,caster);
	else:
		velocity.x = 0;
