extends PlayerState

var activated = true

func state_process(_delta: float) -> void:
	if activated and !parent.isSuper:
		var remVel = parent.movement
		var lastAnim = parent.animator.current_animation
		# hide shield
		parent.shieldSprite.visible = false
		# set movement to 0
		parent.movement = Vector2.ZERO
		activated = false
		
		# play super animation
		parent.sfx[18].play()
		parent.animator.play("super")
		# wait for aniamtion to finish before activating super completely
		await parent.animator.animation_finished
		
		if parent.ground:
			parent.animator.play(lastAnim)
		else:
			parent.animator.play("walk")
		# enable control again
		parent.set_state(parent.STATES.AIR)
		activated = true
		
		# start super theme
		Global.currentTheme = 0
		Global.effectTheme.stream = Global.themes[Global.currentTheme]
		Global.effectTheme.play()
		# swap sprite if sonic
		if parent.character == Global.CHARACTERS.SONIC:
			parent.sprite.texture = parent.superSprite
		# reset velocity to memory
		parent.movement = remVel
		parent.isSuper = true
		print("isSuper set to true")
		parent.switch_physics()
		parent.supTime = 1
	
	# if already super just go to air state
	elif parent.isSuper:
		parent.set_state(parent.STATES.AIR)


func state_exit():
	activated = true
