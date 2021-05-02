tool
extends KinematicBody2D

export (int, "Yellow", "Red") var type = 0;
export (int, "Up", "Down", "Right", "Left", "Diagonal Up Right", "Diagonal Up Left", "Diagonal Down Right", "Diagonal Down Left") var springDirection = 0;
var animList = ["SpringUp","SpringRight","SpringUpLeft","SpringUpRight"];
var dirMemory = springDirection;
var springTextures = [preload("res://Graphics/Gimmicks/springs_yellow.png"),preload("res://Graphics/Gimmicks/springs_red.png")];
var speed = [10,16];



func _ready():
	$Spring.texture = springTextures[type];

func _process(delta):
	if Engine.editor_hint:
		if (springDirection != dirMemory):
			dirMemory = springDirection;
			match (springDirection):
				0, 1:
					$SpringAnimator.play(animList[0]);
					$SpringAnimator.advance($SpringAnimator.get_animation(animList[0]).length);
					$HitBox.rotation_degrees = 0;
					scale = Vector2(1,1-(springDirection*2));
				2, 3:
					$SpringAnimator.play(animList[1]);
					$SpringAnimator.advance($SpringAnimator.get_animation(animList[1]).length);
					$HitBox.rotation_degrees = 90;
					scale = Vector2(1-((springDirection-2)*2),1);
				4, 6:
					$SpringAnimator.play(animList[3]);
					$SpringAnimator.advance($SpringAnimator.get_animation(animList[3]).length);
					scale = Vector2(1,1-(springDirection-4));
				5, 7:
					$SpringAnimator.play(animList[2]);
					$SpringAnimator.advance($SpringAnimator.get_animation(animList[2]).length);
					scale = Vector2(1,1-(springDirection-5));
					
		if ($Spring.texture != springTextures[type]):
			$Spring.texture = springTextures[type];

func _physics_process(delta):
	if !Engine.editor_hint:
		var get = move_and_collide(Vector2.UP,true,true,true);
		if (get):
			get = get.collider;
			if (get.get("velocity") != null):
				get.velocity = Vector2.UP*scale.rotated(rotation)*speed[type]*60;
				$SpringAnimator.play("SpringUp");
				get.set_state(get.STATES.AIR);
				$sfxSpring.play();
