extends Node2D
# timer used for time to a room change
var timer = 0
# active is set to true when the player enters the ring
var active = false

var player = null

func _ready():
	# check that the current ring hasn't already been collected and all 7 emeralds aren't collected
	# the emerald check is so that it'll spawn if you have all emeralds anyway
	if Global.nodeMemory.has(get_path()) and Global.emeralds < 127:
		queue_free()

func _process(delta):
	if active:
		# stop level timer (prevents time over)
		Global.timerActive = false
		# increase timer
		timer += delta
		if timer < 1 and timer+delta >= 1:
			active = false
			
			Global.music.stop()
			Global.effectTheme.stop()
			Global.bossMusic.stop()
			$Warp.play()
			
			# add ring to node memory so you can't farm the ring
			Global.nodeMemory.append(get_path())
			Global.checkPointPosition = global_position
			Global.checkPointRings = Global.players[0].rings
			Global.checkPointTime = Global.levelTime
			
			# fade to new scene
			Main.change_scene("res://Scene/SpecialStage/SpecialStageResult.tscn","WhiteOut",1,false)
			# wait for scene to fade
			await Main.scene_faded
	# Spinning ring logic
	else:
		# loop the spawn animation
		if !$VisibleOnScreenNotifier2D.is_on_screen():
			$Ring.play("spawn")
		else:
			if !$Ring.is_playing():
				$Ring.play("default")

func _on_Hitbox_body_entered(body):
	# check if not active and that the player is player 1
	if !active and body.playerControl == 1 and visible:
		# if 7 emeraldsn haven't been collected, go to special stage
		if Global.emeralds < 127:
			active = true
			body.visible = false
			body.movement = Vector2.ZERO
			# set players state to animation so nothing takes them out of it
			body.set_state(body.STATES.ANIMATION)
			body.collision_layer = 0
			body.collision_mask = 0
			player = body
			body.invTime = 0
			Main.sceneCanPause = false
		else:
			body.rings += 50
		
		# play sound
		$RingEnter.play()
		# play animation
		$Ring.play("enter")
		await $Ring.animation_finished
		# set visible to false after animation's complete
		visible = false
		$Hitbox/CollisionShape2D.disabled = true

# play spawning animation when the ring enters the screen
func _on_VisibilityNotifier2D_viewport_entered(_viewport):
	$Ring.play("spawn")
	$Ring.frame = 0
	await $Ring.animation_finished
	$Ring.play("default")
