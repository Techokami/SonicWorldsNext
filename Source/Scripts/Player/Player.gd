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

var spindashPower = 0.0;
var abilityUsed = false;
var bounceReaction = 0;
var invTime = 0;
var supTime = 0;
var ringDisTime = 0; # ring collecting disable timer

# ================

var Ring = preload("res://Entities/Items/Ring.tscn");
var ringChannel = 0;

var Star = preload("res://Entities/Misc/StarParticle.tscn");

# ================

var lockTimer = 0;
var spriteRotation = 0;

enum STATES {NORMAL, AIR, JUMP, ROLL, SPINDASH, ANIMATION, HIT, CORKSCREW, JUMPCANCEL};
var currentState = STATES.NORMAL;
enum SHIELDS {NONE, NORMAL, ELEC, FIRE, BUBBLE};
var shield = SHIELDS.NONE;
onready var magnetShape = $RingMagnet/CollisionShape2D;

onready var stateList = $States.get_children();
onready var animator = $AnimationSonic;
onready var sprite = $PlayerSprite;
onready var spriteFrames = sprite.frames;
onready var shieldSprite = $Shields;
onready var camera = get_node_or_null("Camera");

var rotatableSprites = ["walk", "run", "peelOut"];
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

# Player values
var shieldID = 0;
var rings = 0;

# How far in can the player can be towards the screen edge before they're clamped
var cameraMargin = 16;

# ALL CODE IS TEMPORARY!

func _ready():
	# initialize controls
	for i in INPUTS:
		inputs.append(0);
	
	# disable and enable states
	set_state(currentState);
	Global.players.append(self);
	

func _input(event):
	if (playerControl != 0):
		if (event.is_action("gm_action")):
			inputs[INPUTS.ACTION] = GlobalFunctions.calculate_input(event,"gm_action");
	


func _process(delta):
	if (ground):
		spriteRotation = rad2deg(angle.angle())+90;
	else:
		if (spriteRotation+180 >= 180):
			spriteRotation = max(0,spriteRotation-(168.75*delta));
		else:
			spriteRotation = min(360,spriteRotation+(168.75*delta));
	
	if (rotatableSprites.has(sprite.animation)):
		sprite.rotation_degrees = stepify(spriteRotation,45)-rotation_degrees;
	else:
		sprite.rotation = -rotation;
	
	if (lockTimer > 0):
		lockTimer -= delta;
		inputs[INPUTS.XINPUT] = 0;
		inputs[INPUTS.YINPUT] = 0;
	if (supTime > 0):
		supTime -= delta;
		if (supTime <= 0):
			if (shield != SHIELDS.NONE):
				shieldSprite.visible = true;
			$InvincibilityBarrier.visible = false;
			
	if (invTime > 0):
		visible = !visible;
		invTime -= delta*Global.originalFPS;
		if (invTime <= 0):
			invTime = 0;
			visible = true;
	if (ringDisTime > 0):
		ringDisTime -= delta;
		
		
	#Rotating stars
	if ($InvincibilityBarrier.visible):
		var stars = $InvincibilityBarrier.get_children();
		for i in stars:
			i.position = i.position.rotated(deg2rad(360*delta*2));
			if (fmod(Global.levelTime,0.1)+delta > 0.1):
				var star = Star.instance();
				star.global_position = i.global_position;
				get_parent().add_child(star);
				star.frame = rand_range(0,3);

func _physics_process(delta):
	
	if (ground):
		groundSpeed = velocity.x;
	
	if (playerControl != 0 && lockTimer <= 0):
		inputs[INPUTS.XINPUT] = -int(Input.is_action_pressed("gm_left"))+int(Input.is_action_pressed("gm_right"));
		inputs[INPUTS.YINPUT] = -int(Input.is_action_pressed("gm_up"))+int(Input.is_action_pressed("gm_down"));
	
	# Boundry Handling
	if (camera != null):
		# Stop velocity at borders
		if (global_position.x < camera.limit_left+cameraMargin || global_position.x > camera.limit_right-cameraMargin):
			velocity.x = 0;
		# Clamp position
		global_position.x = clamp(global_position.x,camera.limit_left+cameraMargin,camera.limit_right-cameraMargin);

func set_state(newState, forceMask = Vector2.ZERO):
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

# set shields
func set_shield(shieldID):
	magnetShape.shape.radius = 0;
	shield = shieldID;
	shieldSprite.visible = true;
	match (shield):
		SHIELDS.NORMAL:
			shieldSprite.play("Default");
			sfx[5].play();
		SHIELDS.ELEC:
			shieldSprite.play("Elec");
			sfx[10].play();
			magnetShape.shape.radius = 64;
		SHIELDS.FIRE:
			shieldSprite.play("Fire");
			sfx[11].play();
		SHIELDS.BUBBLE:
			shieldSprite.play("Bubble");
			sfx[12].play();
		_: # disable
			shieldSprite.visible = false;

func action_jump(animation = "roll", airJumpControl = true):
	sprite.play(animation);
	velocity.y = -jmp;
	sfx[0].play();
	airControl = airJumpControl;

func connect_to_floor():
	if (!ground):
		ground = true;
		abilityUsed = false;
		# landing velocity calculation
		var calcAngle = rad2deg(angle.angle())+90;
		if (calcAngle < 0):
			calcAngle += 360;
		
		# check not shallow
		if (calcAngle >= 22.5 && calcAngle <= 337.5 && abs(velocity.x) < velocity.y):
			# check half steep
			if (calcAngle < 45 || calcAngle > 315):
				velocity.x = velocity.y*0.5*-sign(sin(-deg2rad(90)+angle.angle()));
			# else do full steep
			else:
				velocity.x = velocity.y*-sign(sin(-deg2rad(90)+angle.angle()));
		
		#Bounce reaction
		if (bounceReaction > 0):
			velocity.y = -bounceReaction*Global.originalFPS;
			bounceReaction = 0;
		#Shield Checks
		match (shield):
			SHIELDS.FIRE:
				shieldSprite.play("Fire");
				shieldSprite.flip_h = false;
			SHIELDS.BUBBLE:
				shieldSprite.play("Bubble");

func hit_player(damagePoint = global_position, damageType = 0, soundID = 4):
	if (currentState != STATES.HIT && invTime <= 0 && supTime <= 0):
		velocity.x = sign(global_position.x-damagePoint.x)*2*Global.originalFPS;
		velocity.y = -4*Global.originalFPS;
		if (velocity.x == 0):
			velocity.x = 2*Global.originalFPS;
		
		ground = false;
		set_state(STATES.HIT);
		# Temp code
		# Ring loss
		if (shield == SHIELDS.NONE && rings > 0):
			sfx[9].play();
			ringDisTime = 64/Global.originalFPS;
			var ringCount = 0;
			var ringAngle = 101.25;
			var ringAlt = false;
			var ringSpeed = 4;
			while (ringCount < min(rings,32)):
				# Create ring
				var ring = Ring.instance();
				ring.global_position = global_position;
				ring.scattered = true;
				ring.velocity.y = -sin(deg2rad(ringAngle))*ringSpeed*Global.originalFPS;
				ring.velocity.x = cos(deg2rad(ringAngle))*ringSpeed*Global.originalFPS;
				
				if (ringAlt):
					ring.velocity.x *= -1;
					ringAngle += 22.5;
				ringAlt = !ringAlt;
				ringCount += 1;
				# if we're on the second circle, decrease the speed
				if (ringCount == 16):
					ringSpeed = 2;
					ringAngle == 101.25; # Reset angle
				get_parent().add_child(ring);
				
			rings = 0;
		else:
			sfx[soundID].play();
		
		# Disable Shield
		set_shield(SHIELDS.NONE);
		return true;
	return false;

func get_ring():
	rings += 1;
	#sfx[7+ringChannel].play();
	sfx[7].play();
	ringChannel = int(!ringChannel);
