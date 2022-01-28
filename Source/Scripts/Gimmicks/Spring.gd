@tool
extends CharacterBody2D

@export_enum("Yellow", "Red") var type = 0;
@export_enum("Up", "Down", "Right", "Left", "Diagonal Up Right", "Diagonal Up Left", "Diagonal Down Right", "Diagonal Down Left") var springDirection = 0;
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
			$HitBox.disabled = false;
			$DiagonalHitBox/AreaShape.disabled = true;
			animID = 0;
			$HitBox.rotation_degrees = 0;
			scale = Vector2(1,1-(springDirection*2));
			hitDirection = Vector2(0,-1+(springDirection*2));
		2, 3:
			$HitBox.disabled = false;
			$DiagonalHitBox/AreaShape.disabled = true;
			animID = 1;
			$HitBox.rotation_degrees = 90;
			scale = Vector2(1-((springDirection-2)*2),1);
			hitDirection = Vector2(1-((springDirection-2)*2),0);
		4, 6:
			$HitBox.disabled = true;
			$DiagonalHitBox/AreaShape.disabled = false;
			animID = 3;
			scale = Vector2(1,1-(springDirection-4));
			# place .normalized() at the end for CD physics
			hitDirection = scale*Vector2(1,-1);
		5, 7:
			$HitBox.disabled = true;
			$DiagonalHitBox/AreaShape.disabled = false;
			animID = 2;
			scale = Vector2(1,1-(springDirection-5));
			# place .normalized() at the end for CD physics
			hitDirection = -scale;
			
	$SpringAnimator.play(animList[animID]);
	$SpringAnimator.advance($SpringAnimator.get_animation(animList[animID]).length);
	if ($Spring.texture != springTextures[type]):
		$Spring.texture = springTextures[type];

# Horizontal check
func physics_wall_override(body,caster):
	if (!caster.get_collision_normal().is_equal_approx(hitDirection)):
		body.velocity.x = 0;
	else:
		body.velocity = hitDirection.rotated(rotation).rotated(-body.rotation)*speed[type]*60;
		$SpringAnimator.play(animList[animID]);
		$sfxSpring.play();

# Ceiling check
func physics_ceiling_override(body,caster):
	if (!caster.get_collision_normal().is_equal_approx(hitDirection)):
		body.velocity.y = 0;
	else:
		body.velocity = hitDirection.rotated(rotation).rotated(-body.rotation)*speed[type]*60;
		$SpringAnimator.play(animList[animID]);
		body.spriteFrames.set_animation_speed("walk",1);
		body.set_state(body.STATES.AIR);
		$sfxSpring.play();
	return true;

# Floor check
func physics_floor_override(body,caster):
	if (caster.get_collision_normal().is_equal_approx(hitDirection)):
		body.ground = false;
		body.velocity = hitDirection.rotated(rotation).rotated(-body.rotation)*speed[type]*60;
		$SpringAnimator.play(animList[animID]);
		body.spriteFrames.set_animation_speed("corkScrew",10);
		body.set_state(body.STATES.AIR);
		body.sprite.play("corkScrew");
		$sfxSpring.play();
	return true;


func _on_Diagonal_body_entered(body):
	body.velocity = hitDirection.rotated(rotation).rotated(-body.rotation)*speed[type]*60;
	$SpringAnimator.play(animList[animID]);
	body.spriteFrames.set_animation_speed("corkScrew",10);
	if (hitDirection.y < 0):
		body.set_state(body.STATES.AIR);
	body.sprite.play("corkScrew");
	$sfxSpring.play();
