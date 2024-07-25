@tool
extends StaticBody2D

@export_enum("Yellow", "Red") var type = 0
@export_enum("Up", "Down", "Right", "Left", "Diagonal Up Right", "Diagonal Up Left", "Diagonal Down Right", "Diagonal Down Left") var springDirection = 0
var hitDirection = Vector2.UP
var animList = ["SpringUp","SpringRight","SpringUpLeft","SpringUpRight"]
var animID = 0
var dirMemory = springDirection
var typeMemory = type
var speed = [10,16]

var springTextures = [preload("res://Graphics/Gimmicks/springs_yellow.png"),preload("res://Graphics/Gimmicks/springs_red.png")]

@export var springSound = preload("res://Audio/SFX/Gimmicks/Springs.wav")

func _ready():
	set_spring()

func _process(_delta):
	if Engine.is_editor_hint():
		if (springDirection != dirMemory or typeMemory != type):
			dirMemory = springDirection
			typeMemory = type
			set_spring()


func set_spring():
	match (springDirection):
		0, 1: # up, down
			$HitBox.disabled = false
			$DiagonalHitBox/AreaShape.disabled = true
			animID = 0
			$HitBox.rotation = deg_to_rad(0)
			scale = Vector2(1,1-(springDirection*2))
			hitDirection = Vector2(0,-1+(springDirection*2))
		2, 3: # right, left
			$HitBox.disabled = false
			$DiagonalHitBox/AreaShape.disabled = true
			animID = 1
			$HitBox.rotation = deg_to_rad(90)
			scale = Vector2(1-((springDirection-2)*2),1)
			hitDirection = Vector2(1-((springDirection-2)*2),0)
		4, 6: #diagonal right
			$HitBox.disabled = true
			$DiagonalHitBox/AreaShape.disabled = false
			animID = 3
			scale = Vector2(1,1-(springDirection-4))
			# place super.normalized() at the end for CD physics
			hitDirection = scale*Vector2(1,-1)
		5, 7: #diagonal left
			$HitBox.disabled = true
			$DiagonalHitBox/AreaShape.disabled = false
			animID = 2
			scale = Vector2(1,1-(springDirection-5))
			# place super.normalized() at the end for CD physics
			hitDirection = -scale
			
	$SpringAnimator.play(animList[animID])
	$SpringAnimator.advance($SpringAnimator.get_animation(animList[animID]).length)
	if $Spring.texture != springTextures[type]:
		$Spring.texture = springTextures[type]

# Collision check
func physics_collision(body, hitVector):
	# check that the players hit direction matches the direction we're facing (ignored for diagonal)
	if hitVector == -hitDirection:
		# do a Rock launch HAUGH!!!
		var setMove = hitDirection.rotated(rotation).rotated(-body.rotation).round()*speed[type]*60
		# vertical movement
		if setMove.y != 0:
			# disable ground
			body.ground = false
			body.set_state(body.STATES.AIR)
			# figure out the animation based on the players current animation
			var curAnim = "walk"
			match(body.animator.current_animation):
				"walk", "run", "peelOut":
					curAnim = body.animator.current_animation
				# if none of the animations match and speed is equal beyond the players top speed, set it to run (default is walk)
				_:
					if(abs(body.groundSpeed) >= min(6*60,body.top)):
						curAnim = "run"
			# play player animation
			body.animator.play("spring")
			body.animator.queue(curAnim)
			# set vertical speed
			body.movement.y = setMove.y
			body.set_state(body.STATES.AIR)
		# horizontal movement
		else:
			# exit out of state on certain states
			match(body.currentState):
				body.STATES.GLIDE:
					if !body.ground:
						body.animator.play("run")
						body.set_state(body.STATES.AIR)
			# set horizontal speed
			body.movement.x = setMove.x
			body.horizontalLockTimer = (15.0/60.0) # lock for 15 frames
			body.direction = sign(setMove.x)
		$SpringAnimator.play(animList[animID])
		Global.play_sound(springSound)
		
		#Restore Air Control
		body.airControl = true
		# Disable pole grabs
		body.poleGrabID = self
		return true
	

func _on_Diagonal_body_entered(body):
	# diagonal springs are pretty straightforward
	body.movement = hitDirection.rotated(rotation).rotated(-body.rotation)*speed[type]*60
	$SpringAnimator.play(animList[animID])
	if (hitDirection.y < 0):
		body.set_state(body.STATES.AIR)
		# figure out the animation based on the players current animation
		var curAnim = "walk"
		match(body.animator.current_animation):
			"walk", "run", "peelOut":
				curAnim = body.animator.current_animation
			# if none of the animations match and speed is equal beyond the players top speed, set it to run (default is walk)
			_:
				if(abs(body.groundSpeed) >= min(6*60,body.top)):
					curAnim = "run"
		# play player animation
		body.animator.play("springScrew")
		body.animator.queue(curAnim)
	Global.play_sound(springSound)
	# Disable pole grabs
	body.poleGrabID = self
