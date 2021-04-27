extends "res://Scripts/Objects/PhysicsObject.gd"


#Sonic's Speed constants
var acc = 0.046875;			#acceleration
var dec = 0.5;				#deceleration
var frc = 0.046875;			#friction (same as acc)
var top = 6*60;				#top horizontal speed
var slp = 0.125;			#slope factor when walking/running
var slprollup = 0.078125;	#slope factor when rolling uphill
var slprolldown = 0.3125;	#slope factor when rolling downhill
var fall = 2.5*60;				#tolerance ground speed for sticking to walls and ceilings

#Sonic's Airborne Speed Constants
var air = 0.09375;			#air acceleration (2x acc)
var jmp = 6.5*60;				#jump force (6 for knuckles)
var grv = 0.21875;			#gravity

var lockTimer = 0;
var spriteRotation = 0;

enum STATES {NORMAL, AIR, ROLL};
var currentState = STATES.NORMAL;
onready var stateList = $States.get_children();

onready var animator = $AnimationSonic;
onready var sprite = $Sprite;

enum INPUTS {XINPUT, YINPUT, ACTION, ACTION2, ACTION3, SUPER, PAUSE};
# Input control, 0 = 0ff, 1 = On
# (for held it's best to use inputs[INPUTS.ACTION] > 0)
# XInput and YInput are directions and are either -1, 0 or 1.
var inputs = [];
# 0 = ai, 1 = player 1, 2 = player 2
var playerControl = 1;

onready var sfx = $SFX.get_children();

# ALL CODE IS TEMPORARY!

func _ready():
	# initialize controls
	for i in INPUTS:
		inputs.append(0);
	
	# disable and enable states
	set_state(currentState);
	

func _input(event):
	if (playerControl != 0):
		# I wanted to do match statements but afaik at least right now I don't know how to do it
		# with functions yet
		if (event.is_action("gm_left") || event.is_action("gm_right")):
			inputs[INPUTS.XINPUT] = sign(-int(event.is_action("gm_left"))+int(event.is_action_released("gm_left"))
			+int(event.is_action("gm_right"))-int(event.is_action_released("gm_right")));
			
		elif (event.is_action("gm_up") || event.is_action("gm_down")):
			inputs[INPUTS.YINPUT] = sign(-int(event.is_action("gm_up"))+int(event.is_action_released("gm_up"))
			+int(event.is_action("gm_down"))-int(event.is_action_released("gm_down")));
		
		elif (event.is_action("gm_action")):
			inputs[INPUTS.ACTION] = GlobalFunctions.calculate_input(event,"gm_action");
	


func _process(delta):
	if (ground):
		spriteRotation = rad2deg(angle.angle())+90;
	else:
		if (spriteRotation < 180):
			spriteRotation = max(0,spriteRotation-(168.75*delta));
		else:
			spriteRotation = min(360,spriteRotation+(168.75*delta));
	
	$Sprite.rotation_degrees = stepify(spriteRotation,45)-rotation_degrees;


func _physics_process(delta):
	
	#if (!ground):
		#velocity.x = inputDir*top;
	#if (Input.is_action_just_pressed("gm_action")):
		#$SFX/SpindashRev.pitch_scale = 0.95;

	if (Input.is_action_just_pressed("gm_down")):
		if ($SFX/SpindashRev.pitch_scale < 1.5):
			$SFX/SpindashRev.pitch_scale += 0.05;
		sfx[1].play();
		velocity.x += 30;

func set_state(newState):
	for i in stateList:
		i.set_process(i == stateList[newState]);
		i.set_physics_process(i == stateList[newState]);
		i.set_process_input(i == stateList[newState]);
	currentState = newState;


func action_jump(animation = "Roll"):
	$AnimationSonic.play(animation);
	velocity.y = -jmp;
	sfx[0].play();

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

