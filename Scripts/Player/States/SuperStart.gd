extends PlayerState

var activated = true

func state_process(_delta: float) -> void:
	var animator: PlayerCharAnimationPlayer = parent.get_avatar().get_animator()
	if activated and !parent.isSuper:
		var remVel = parent.movement
		var lastAnim = animator.current_animation
		# hide shield
		parent.shieldSprite.visible = false
		# set movement to 0
		parent.movement = Vector2.ZERO
		activated = false
		
		# play super animation
		parent.sfx[18].play()
		animator.play("super")
		# wait for aniamtion to finish before activating super completely
		await animator.animation_finished
		
		if parent.ground:
			animator.play(lastAnim)
		else:
			animator.play("walk")
		# enable control again
		parent.set_state(parent.STATES.AIR)
		activated = true
		
		# start super theme
		Global.currentTheme = 0
		Global.effectTheme.stream = Global.themes[Global.currentTheme]
		Global.effectTheme.play()
		
		# Start graphics changes needed to go super
		parent.get_avatar().go_super()
		
		# reset velocity to memory
		parent.movement = remVel
		parent.isSuper = true
		parent.switch_physics()
		parent.supTime = 1
	
	# if already super just go to air state
	elif parent.isSuper:
		parent.set_state(parent.STATES.AIR)


func state_exit():
	activated = true
