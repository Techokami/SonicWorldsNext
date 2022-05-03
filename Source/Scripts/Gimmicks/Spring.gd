tool
extends StaticBody2D

export (int, "Yellow", "Red") var type = 0
export (int, "Up", "Down", "Right", "Left", "Diagonal Up Right", "Diagonal Up Left", "Diagonal Down Right", "Diagonal Down Left") var springDirection = 0
var hitDirection = Vector2.UP
var animList = ["SpringUp","SpringRight","SpringUpLeft","SpringUpRight"]
var animID = 0
var dirMemory = springDirection
var springTextures = [preload("res://graphics/gimmicks/springs_yellow.png"),preload("res://graphics/gimmicks/springs_red.png")]
var speed = [10,16]

func _ready():
	set_spring()

func _process(delta):
	if Engine.is_editor_hint():
		if (springDirection != dirMemory):
			dirMemory = springDirection
			set_spring()


func set_spring():
	match (springDirection):
		0, 1:
			$HitBox.disabled = false
			$DiagonalHitBox/AreaShape.disabled = true
			animID = 0
			$HitBox.rotation = deg2rad(0)
			scale = Vector2(1,1-(springDirection*2))
			hitDirection = Vector2(0,-1+(springDirection*2))
		2, 3:
			$HitBox.disabled = false
			$DiagonalHitBox/AreaShape.disabled = true
			animID = 1
			$HitBox.rotation = deg2rad(90)
			scale = Vector2(1-((springDirection-2)*2),1)
			hitDirection = Vector2(1-((springDirection-2)*2),0)
		4, 6:
			$HitBox.disabled = true
			$DiagonalHitBox/AreaShape.disabled = false
			animID = 3
			scale = Vector2(1,1-(springDirection-4))
			# place .normalized() at the end for CD physics
			hitDirection = scale*Vector2(1,-1)
		5, 7:
			$HitBox.disabled = true
			$DiagonalHitBox/AreaShape.disabled = false
			animID = 2
			scale = Vector2(1,1-(springDirection-5))
			# place .normalized() at the end for CD physics
			hitDirection = -scale
			
	$SpringAnimator.play(animList[animID])
	$SpringAnimator.advance($SpringAnimator.get_animation(animList[animID]).length)
	if ($Spring.texture != springTextures[type]):
		$Spring.texture = springTextures[type]

# Collision check
func physics_collision(body, hitVector):
	if hitVector == -hitDirection:
		#body.ground = false
		var setMove = hitDirection.rotated(rotation).rotated(-body.rotation).round()*speed[type]*60
		if setMove.y != 0:
			body.ground = false
			body.set_state(body.STATES.AIR)
			var curAnim = "walk"
			match(body.animator.current_animation):
				"walk", "run", "peelOut":
					curAnim = body.animator.current_animation
				_:
					if(abs(body.groundSpeed) >= min(6*60,body.top)):
						curAnim = "run"
			body.animator.play("spring")
			body.animator.queue(curAnim)
			body.movement.y = setMove.y
		else:
			body.movement.x = setMove.x
		$SpringAnimator.play(animList[animID])
		$sfxSpring.play()
		return true
	

func _on_Diagonal_body_entered(body):
	body.movement = hitDirection.rotated(rotation).rotated(-body.rotation)*speed[type]*60
	$SpringAnimator.play(animList[animID])
	if (hitDirection.y < 0):
		body.set_state(body.STATES.AIR)
		body.animator.play("corkScrew")
	$sfxSpring.play()
