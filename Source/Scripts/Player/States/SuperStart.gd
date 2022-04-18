extends "res://Scripts/Player/State.gd"

var activated = true

func _process(delta):
	if activated && !parent.super:
		var remVel = parent.movement
		var lastAnim = parent.animator.current_animation
		parent.shieldSprite.visible = false
		parent.movement = Vector2.ZERO
		activated = false
		parent.sfx[18].play()
		parent.animator.play("super")
		# wait for aniamtion to finish before activating super completely
		yield(parent.animator,"animation_finished")
		
		parent.switch_physics(4)
		parent.animator.play(lastAnim)
		parent.set_state(parent.STATES.AIR)
		activated = true
		Global.music.stream_paused = true
		Global.currentTheme = 0
		Global.effectTheme.stream = Global.themes[Global.currentTheme]
		Global.effectTheme.play()
		parent.sprite.texture = parent.superSprite
		parent.movement = remVel
		parent.super = true
		parent.supTime = 1

func state_exit():
	activated = true
