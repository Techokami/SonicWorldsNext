extends "res://Scripts/Objects/PhysicsObject.gd"

const HITBOXESSONIC = {NORMAL = Vector2(9,19), ROLL = Vector2(7,14)};

#Sonic's Speed constants
var acc = 0.046875;			#acceleration
var dec = 0.5;				#deceleration
var frc = 0.046875;			#friction (same as acc)
var rollfrc = frc*0.5;		#roll friction
var rolldec = 0.125;		#roll deceleration
var top = 6*60;				#top horizontal speed
var toproll = 16*60;		#top horizontal speed rolling
var slp = 0.125;			#slope factor when walking/running
var slprollup = 0.078125;	#slope factor when rolling uphill
var slprolldown = 0.3125;	#slope factor when rolling downhill
var fall = 2.5*60;			#tolerance ground speed for sticking to walls and ceilings

#Sonic's Airborne Speed Constants
var air = 0.09375;			#air acceleration (2x acc)
var jmp = 6.5*60;			#jump force (6 for knuckles)
var grv = 0.21875;			#gravity

#Varaibles are guessed, more research needs to be made into these

var spindashPower = 0;
var spindashTap = 1.0/10.0;
var spindash = 14*60;
var minSpindash = 4*60;

# ================

var lockTimer = 0;
var spriteRotation = 0;

enum STATES {NORMAL, AIR, JUMP, ROLL, SPINDASH, ANIMATION};
var currentState = STATES.NORMAL;
onready var stateList = $States.get_children();

onready var animator = $AnimationSonic;
onready var sprite = $Sprite;
var rotatableSprites = ["Walk", "Run"];
var direction = scale.x;
# ground speed is mostly used for timing and animations, there isn't any functionality to it.
var groundSpeed = velocity.x;

enum INPUTS {XINPUT, YINPUT, ACTION, ACTION2, ACTION3, SUPER, PAUSE};
# Input control, 0 = 0ff, 1 = On
# (for held it's best to use inputs[INPUTS.ACTION] > 0)
# XInput and YInput are directions and are either -1, 0 or 1.
var inputs = [];
# 0 = ai, 1 = player 1, 2 = player 2
var playerControl = 1;

onready var sfx = $SFX.get_children();
var airControl = true;

# ALL CODE IS TEMPORARY!

func _ready():
	# initialize controls
	for i in INPUTS:
		inputs.append(0);
	
	# disable and enable states
	set_state(currentState);
	

func _input(event):
	if (playerControl != 0):
		if (event.is_action("gm_action")):
			inputs[INPUTS.ACTION] = GlobalFunctions.calculate_input(event,"gm_action");
	


func _process(delta):
	if (ground):
		spriteRotation = rad2deg(angle.angle())+90;
	else:
		if (spriteRotation < 180):
			spriteRotation = max(0,spriteRotation-(168.75*delta));
		else:
			spriteRotation = min(360,spriteRotation+(168.75*delta));
	
	if (rotatableSprites.has($AnimationSonic.current_animation)):
		$Sprite.rotation_degrees = stepify(spriteRotation,45)-rotation_degrees;
	else:
		$Sprite.rotation = -rotation;
	
	if (lockTimer > 0):
		lockTimer -= delta;
		inputs[INPUTS.XINPUT] = 0;
		inputs[INPUTS.YINPUT] = 0;

func _physics_process(delta):
	if (ground):
		groundSpeed = velocity.x;
	if (playerControl != 0 && lockTimer <= 0):
		inputs[INPUTS.XINPUT] = -int(Input.is_action_pressed("gm_left"))+int(Input.is_action_pressed("gm_right"));
		inputs[INPUTS.YINPUT] = -int(Input.is_action_pressed("gm_up"))+int(Input.is_action_pressed("gm_down"));


func set_state(newState, forceMask = Vector2.ZERO):
	animator.playback_speed = 1;
	for i in stateList:
		i.set_process(i == stateList[newState]);
		i.set_physics_process(i == stateList[newState]);
		i.set_process_input(i == stateList[newState]);
	currentState = newState;
	var shapeChangeCheck = $HitBox.shape.extents;
	if (forceMask == Vector2.ZERO):
		match(newState):
			STATES.JUMP, STATES.ROLL:
				$HitBox.shape.extents = HITBOXESSONIC.ROLL;
			_:
				$HitBox.shape.extents = HITBOXESSONIC.NORMAL;
	else:
		$HitBox.shape.extents = forceMask;
	update_sensors();
	update_raycasts();
	# snap to floor if old shape is smaller then new shape
	if (shapeChangeCheck.y < $HitBox.shape.extents.y):
		var getFloor = get_closest_sensor(floorCastLeft,floorCastRight);
		if (getFloor):
			position += getFloor.get_collision_point()-getFloor.global_position-($HitBox.shape.extents*Vector2(0,1)).rotated(rotation);


func action_jump(animation = "Roll", airJumpControl = true):
	$AnimationSonic.play(animation);
	velocity.y = -jmp;
	sfx[0].play();
	airControl = airJumpControl;

func connect_to_floor():
	if (!ground):
		ground = true;
		
		# landing velocity calculation
		var calcAngle = rad2deg(angle.angle())+90;
		if (calcAngle < 0):
			calcAngle += 360;
		
		# check not shallow
		if (calcAngle >= 22.5 && calcAngle <= 337.5 && abs(velocity.x) < velocity.y):
			# check half steep
			if (calcAngle < 45 || calcAngle > 315):
				velocity.x = velocity.y*0.5*-sign(sin(-deg2rad(90)+angle.angle()))
			# else do full steep
			else:
				velocity.x = velocity.y*-sign(sin(-deg2rad(90)+angle.angle()))

