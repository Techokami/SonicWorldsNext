tool
extends KinematicBody2D

export (int, "Yellow", "Red") var type = 0;
export (int, "Up", "Down", "Right", "Left", "Diagonal Up Right", "Diagonal Up Left", "Diagonal Down Right", "Diagonal Down Left") var springDirection = 0;
var hitDirection = Vector2.UP;
var animList = ["SpringUp","SpringRight","SpringUpLeft","SpringUpRight"];
var animID = 0;
var dirMemory = springDirection;
var springTextures = [preload("res://Graphics/Gimmicks/springs_yellow.png"),preload("res://Graphics/Gimmicks/springs_red.png")];
var speed = [10,16];



func _ready():
	set_spring();

func _process(delta):
	if Engine.editor_hint:
		if (springDirection != dirMemory):
			dirMemory = springDirection;
			set_spring();


func set_spring():
	match (springDirection):
		0, 1:
			animID = 0;
			$HitBox.rotation_degrees = 0;
			scale = Vector2(1,1-(springDirection*2));
			hitDirection = Vector2(0,-1+(springDirection*2));
		2, 3:
			animID = 1;
			$HitBox.rotation_degrees = 90;
			scale = Vector2(1-((springDirection-2)*2),1);
			hitDirection = Vector2(1-((springDirection-2)*2),0);
		4, 6:
			animID = 3;
			scale = Vector2(1,1-(springDirection-4));
		5, 7:
			animID = 2;
			scale = Vector2(1,1-(springDirection-5));
			
	$SpringAnimator.play(animList[animID]);
	$SpringAnimator.advance($SpringAnimator.get_animation(animList[animID]).length);
	if ($Spring.texture != springTextures[type]):
		$Spring.texture = springTextures[type];

func _physics_process(delta):
	if !Engine.editor_hint:
		var get = move_and_collide(hitDirection.rotated(rotation),true,true,true);
		if (get):
			get = get.collider;
			if (get.get("velocity") != null):
				if (get.ground):
					get.velocity = hitDirection.rotated(rotation)*speed[type]*60;
				print(get.velocity)
				$SpringAnimator.play(animList[animID]);
				if (get.currentState == get.STATES.JUMP):
					get.set_state(get.STATES.AIR);
				get.animator.play("Spring");
				get.animator.playback_speed = 1;
				$sfxSpring.play();
