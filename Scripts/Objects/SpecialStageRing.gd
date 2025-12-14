extends Node2D
# timer used for time to a room change
var timer = 0
# active is set to true when the player enters the ring
var active = false

var player: PlayerChar = null

func _ready() -> void:
	# check that the current ring hasn't already been collected and all 7 emeralds aren't collected
	# the emerald check is so that it'll spawn if you have all emeralds anyway
	if Global.nodeMemory.has(get_path()) and Global.emeralds < Global.EMERALDS.ALL:
		queue_free()

func _process(delta: float) -> void:
	if active:
		# stop level timer (prevents time over)
		Global.timerActive = false
		# increase timer
		timer += delta
		if timer < 1 and timer+delta >= 1:
			active = false
			
			MusicController.reset_music_themes()
			$Warp.play()
			
			# reset the air timer to prevent the drowning theme from playing
			# when entering special stage
			player.airTimer = player.defaultAirTime
			
			Global.bonusStageSavedPosition = global_position
			Global.bonusStageSavedRings = player.rings
			Global.bonusStageSavedTime = Global.levelTime
			
			# Mark as destroyed
			Global.nodeMemory.append(get_path())
			
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

func _on_Hitbox_body_entered(player_entered: PlayerChar) -> void:
	# check if not active and that the player is player 1
	if !active and player_entered.playerControl == 1 and visible:
		# if 7 emeralds haven't been collected, go to special stage
		if Global.emeralds < Global.EMERALDS.ALL:
			active = true
			player_entered.visible = false
			player_entered.movement = Vector2.ZERO
			# set players state to animation so nothing takes them out of it
			player_entered.set_state(player_entered.STATES.GIMMICK)
			player_entered.collision_layer = 0
			player_entered.collision_mask = 0
			self.player = player_entered
			player_entered.invTime = 0
		else:
			player_entered.give_rings(50, false)
		
		# play sound
		$RingEnter.play()
		# play animation
		$Ring.play("enter")
		await $Ring.animation_finished
		# set visible to false after animation's complete
		visible = false
		$Hitbox/CollisionShape2D.disabled = true

# play spawning animation when the ring enters the screen
func _on_VisibilityNotifier2D_viewport_entered(_viewport) -> void:
	$Ring.play("spawn")
	$Ring.frame = 0
	await $Ring.animation_finished
	$Ring.play("default")
