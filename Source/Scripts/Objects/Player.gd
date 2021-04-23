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

func _physics_process(delta):
	inputDir = -int(Input.is_action_pressed("gm_left"))+int(Input.is_action_pressed("gm_right"));
	
	if (ground):
		$AnimationSonic.play("Idle");
		velocity.y = 0;
		if (inputDir != 0):
			if (velocity.x*inputDir < top):
				velocity.x += acc/delta*inputDir;
		else:
			if (velocity.x != 0):
				# needs better code
				velocity.x -= (dec/delta)*sign(velocity.x);
	else:
		velocity = Vector2(velocity.x,velocity.y);
		#velocity.x = inputDir*top;
		velocity.y += grv/delta;
	if (Input.is_action_just_pressed("gm_action")):
		$AnimationSonic.play("Roll");
		velocity.y = -jmp;
		
