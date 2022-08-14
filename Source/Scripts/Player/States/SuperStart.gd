extends "res://Scripts/Player/State.gd"

var activated = true

func _process(_delta):
	if activated && !parent.super:
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
		yield(parent.animator,"animation_finished")
		
		parent.animator.play(lastAnim)
		parent.set_state(parent.STATES.AIR)
		activated = true
		
		Global.currentTheme = 0
		Global.effectTheme.stream = Global.themes[Global.currentTheme]
		Global.effectTheme.play()
		# swap sprite if sonic
		if parent.character == parent.CHARACTERS.SONIC:
			parent.sprite.texture = parent.superSprite
		# reset velocity to memory
		parent.movement = remVel
		parent.super = true
		parent.switch_physics()
		parent.supTime = 1
	# if already super just go to air state
	elif parent.super:
		parent.set_state(parent.STATES.AIR)
		

func state_exit():
	activated = true
