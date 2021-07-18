extends "res://Scripts/Player/State.gd"

var elecPart = preload("res://Entities/Misc/ElecParticles.tscn");

export var isJump = false;

# Jump actions
func _input(event):
	if (parent.playerControl != 0):
		# Shield actions
		if (event.is_action_pressed("gm_action") && !parent.abilityUsed):
			parent.abilityUsed = true;
			match (parent.shield):
				parent.SHIELDS.NONE:
					parent.sfx[16].play();
					parent.shieldSprite.play("Insta");
					parent.shieldSprite.frame = 0;
					parent.shieldSprite.visible = true;
					yield(parent.shieldSprite,"animation_finished");
					# check shields hasn't changed
					if (parent.shield == parent.SHIELDS.NONE):
						parent.shieldSprite.visible = false;
						parent.shieldSprite.stop();
				parent.SHIELDS.ELEC:
					parent.sfx[13].play();
					parent.velocity.y = -5.5*Global.originalFPS;
					for i in range(4):
						var part = elecPart.instance();
						part.global_position = parent.global_position;
						part.direction = Vector2(1,1).rotated(deg2rad(90*i));
						parent.get_parent().add_child(part);
				parent.SHIELDS.FIRE:
					parent.sfx[14].play();
					parent.velocity = Vector2(8*Global.originalFPS*parent.direction,0);
					parent.shieldSprite.play("FireAction");
					parent.shieldSprite.flip_h = (parent.direction < 0);
				parent.SHIELDS.BUBBLE:
					parent.sfx[15].play();
					parent.velocity = Vector2(0,8*Global.originalFPS);
					parent.bounceReaction = 7.5;
					parent.shieldSprite.play("BubbleAction");
					#parent.shieldSprite.frame = ;

func _process(delta):
	if (parent.animator.current_animation == "Roll"):
		parent.animator.playback_speed = (1.0/4.0)+floor(min(4,abs(parent.groundSpeed/60)))/4;
	if (parent.animator.current_animation == "Walk" || parent.animator.current_animation == "Run"):
		parent.animator.playback_speed = (1.0/8.0)+floor(min(8,abs(parent.groundSpeed/60)))/8;

func _physics_process(delta):
	# air movement
	if (parent.inputs[parent.INPUTS.XINPUT] != 0 && parent.airControl):
		if (parent.velocity.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (abs(parent.velocity.x) < parent.top):
				parent.velocity.x = clamp(parent.velocity.x+parent.air/delta*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top);
				
	# Air drag, don't know how accurate this is, may need some better tweaking
	if (parent.velocity.y < 0 && parent.velocity.y > -4*60):
		#parent.velocity.x -= ((parent.velocity.x / int(0.125/delta)) / 256); old version
		parent.velocity.x -= ((parent.velocity.x / 0.125) / 256)*60*delta;
	
	if (isJump && !parent.inputs[parent.INPUTS.ACTION]):
		if (parent.velocity.y < -4*60):
			parent.velocity.y = -4*60;
	
	# gravity
	parent.velocity.y += parent.grv/delta;
	
	if (parent.ground):
		parent.set_state(parent.STATES.NORMAL);
	
	
