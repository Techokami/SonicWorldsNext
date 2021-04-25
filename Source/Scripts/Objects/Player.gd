extends "res://Scripts/Objects/PhysicsObject.gd"

var inputDir = 0;

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

onready var sfx = $SFX.get_children();

# ALL CODE IS TEMPORARY!

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
	inputDir = -int(Input.is_action_pressed("gm_left"))+int(Input.is_action_pressed("gm_right"));
	
	if (ground):
		if (velocity.x == 0):
			$AnimationSonic.play("Idle");
		elif(abs(velocity.x) < top):
			$AnimationSonic.play("Walk");
		else:
			$AnimationSonic.play("Run");
		$AnimationSonic.playback_speed = max(1,abs(velocity.x/top)*1.5);
		
		if (round(velocity.x) != 0):
			$Sprite.flip_h = (velocity.x <= 0);
		
		velocity.y = 0;
		
		# Apply slop factor
		# ignore this if not moving for sonic 1 style slopes
		velocity.x -= (slp*sin(-deg2rad(90)+angle.angle()))/delta;
		
		var calcAngle = rad2deg(angle.angle())+90;
		if (calcAngle < 0):
			calcAngle += 360;
		# drop if speed below fall speed
		if (abs(velocity.x) < fall && calcAngle >= 45 && calcAngle <= 315):
			if (calcAngle >= 90 && calcAngle <= 270):
				disconect_from_floor();
			lockTimer = 30.0/60.0;
		
		if (inputDir != 0):
			if (velocity.x*inputDir < top):
				if (sign(velocity.x) == inputDir):
					velocity.x += acc/delta*inputDir;
				else:
					velocity.x += dec/delta*inputDir;
		else:
			if (velocity.x != 0):
				# needs better code
				if (sign(velocity.x - (frc/delta)*sign(velocity.x)) == sign(velocity.x)):
					velocity.x -= (frc/delta)*sign(velocity.x);
				else:
					velocity.x = 0;
		
		
	else:
		velocity = Vector2(velocity.x,velocity.y);
		#velocity.x = inputDir*top;
		velocity.y += grv/delta;
	if (Input.is_action_just_pressed("gm_action")):
		$AnimationSonic.play("Roll");
		velocity.y = -jmp;
		sfx[0].play();
		$SFX/SpindashRev.pitch_scale = 0.95;
	if (Input.is_action_just_pressed("gm_down")):
		if ($SFX/SpindashRev.pitch_scale < 1.5):
			$SFX/SpindashRev.pitch_scale += 0.05;
		sfx[1].play();
		velocity.x += 30;
		
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

