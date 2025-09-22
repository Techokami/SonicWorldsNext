extends Node2D
# timer used for time to a room change
var timer = 0
# active is set to true when the player enters the ring
var active = false

var player: PlayerChar = null
var maskMemory = []

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
			
			# set next zone to current zone (this will reset when the stage is loaded back in)
			Global.nextZone = Global.main.lastScene
			
			# add ring to node memory so you can't farm the ring
			Global.nodeMemory.append(get_path())
			
			# fade to new scene
			Global.main.change_scene_to_file(load("res://Scene/SpecialStage/SpecialStageResult.tscn"),"WhiteOut","WhiteOut",1,true,false)
			# wait for scene to fade
			await Global.main.scene_faded
			
			if player != null:
				# set player's position to rings (and player 2)
				# helps sell the illusion that we reset the room
				player.global_position = global_position
				player.direction = 1
				# Remember to give the player's air back, they might have been under water
				# imagine if you were underwater and got sucked into another dimension only for when
				# you get back you immediately drown.
				# That's happened in real life plenty of times they just never tell you about it
				# mostly because the people this has happened to have drowned.
				# But this is Sonic the Hedgehog and not real life so this unrealistic change is fine
				player.airTimer = player.defaultAirTime
				
				# check for partner
				var partner: PlayerChar = player.get_partner()
				if partner != null:
					partner.global_position = global_position+Vector2(-32,0)
					partner.direction = 1
					partner.movement = Vector2.ZERO
					partner.velocity = Vector2.ZERO
					# reset state
					partner.set_state(player.partner.STATES.NORMAL)
					# play idle
					partner.get_avatar().get_animator().play("idle")
					# reset the partners air, imagine if you came home and from another dimension and-
					partner.airTimer = player.partner.defaultAirTime
				
				# reset invincibility and shoes (or super low so they player can exit these states normally)
				player.supTime = min(player.supTime,0.01)
				player.shoeTime = min(player.supTime,0.01)
				# reset super phase
				if player.isSuper:
					player.isSuper = false
					if is_instance_valid(player.superAnimator):
						player.superAnimator.play("PowerDown")
				# reset super sonic texture
				var player_avatar: PlayerAvatar = player.get_avatar()
				if player_avatar.super_sprite != null:
					player.sprite.texture = player_avatar.normal_sprite
				# reset physics
				player.switch_physics()
				player.visible = true
				# reset state
				player.set_state(player.STATES.NORMAL)
				# play idle
				player.get_avatar().get_animator().play("idle")
				
				if maskMemory.size() > 0:
					player.collision_layer = maskMemory[0]
					player.collision_mask = maskMemory[1]
				Global.timerActive = true
				queue_free()
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
			# set player collision layer and mask to nothing to avoid collissions
			maskMemory.append(player_entered.collision_layer)
			maskMemory.append(player_entered.collision_mask)
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
