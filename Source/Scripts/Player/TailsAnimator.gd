extends Sprite

onready var tailsAnimator = $TailsAnimator
onready var animator = get_parent().get_parent().get_node("PlayerAnimation")

enum HANDLE {DEFAULT, ROTATE, SPEED}
var currentHandle = HANDLE.DEFAULT

func _process(_delta):
	match(currentHandle):
		HANDLE.DEFAULT:
			rotation = 0
			scale = Vector2(1-(int(get_parent().flip_h)*2),1)
		HANDLE.ROTATE:
			var player = get_parent().get_parent().get_parent()
			if player:
				if player.ground:
					global_rotation = deg2rad(stepify(rad2deg(player.angle),45))-player.gravityAngle
					# uncomment below for smooth rotation
					#global_rotation = player.angle-player.gravityAngle
					if sign(player.movement.x) != 0:
						scale = Vector2(sign(player.movement.x),1)
				else:
					global_rotation = deg2rad(stepify(rad2deg(player.movement.angle()),45))-player.gravityAngle
					# uncomment below for smooth rotation
					#global_rotation = player.movement.angle()-player.gravityAngle
					scale = Vector2(1,1-(int(rad2deg(rotation) > 90 and rad2deg(rotation) < 270)*2))
				

func _on_PlayerAnimation_animation_started(anim_name):
	if tailsAnimator == null:
		return null
	match(anim_name):
		"idle", "idle1", "crouch", "lookUp":
			tailsAnimator.playback_speed = 1
			tailsAnimator.play("default")
			tailsAnimator.advance(0)
			currentHandle = HANDLE.DEFAULT
		"spinDash", "push", "skid", "edge1", "edge2", "edge3":
			tailsAnimator.playback_speed = .5
			tailsAnimator.play("spinDash")
			tailsAnimator.advance(0)
			currentHandle = HANDLE.DEFAULT
		"roll":
			tailsAnimator.playback_speed = 1
			tailsAnimator.play("roll")
			tailsAnimator.advance(0)
			currentHandle = HANDLE.ROTATE
		"fly", "flyCarry", "flyCarryUP":
			tailsAnimator.playback_speed = 1
			tailsAnimator.play("fly")
			tailsAnimator.advance(0)
			currentHandle = HANDLE.DEFAULT
		"tired":
			tailsAnimator.playback_speed = .2
			tailsAnimator.play("fly")
			tailsAnimator.advance(0)
			currentHandle = HANDLE.DEFAULT
		"hang":
			tailsAnimator.playback_speed = .5
			tailsAnimator.play("hang")
			tailsAnimator.advance(0)
			currentHandle = HANDLE.DEFAULT
		"RESET":
			currentHandle = HANDLE.DEFAULT
		_:
			tailsAnimator.play("stop")
			tailsAnimator.advance(0)
			currentHandle = HANDLE.DEFAULT
