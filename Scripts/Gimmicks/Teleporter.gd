@tool
extends Node2D

# TODO - turn into ConnectableGimmick
# TODO - make useful in competitive multiplayer
#        Goals:
#        1. If multiplayer mode is set, any player can activate the beam
#        2. If multiplayer mode is not set, only first player can activae the beam.
#        3. Regardless of multiplayer mode, if a player enters the beam once started, they get
#           put into the beam and sent upwards.
#        4. Beam does not shut down until the last player is sent.
#        5. Beam is only connectable at the base of the beam -- not at the place where the beam
#           drops players off.
#
#        The only original in-game example of multiple characters being able to ride a teleporter
#        is the one at the end of Hidden Palace that takes everyone to Sky Sanctuary, but that's
#        still the ideal one to model off of even if it's just a cutscene.
#
# TODO - fix blinking on animation

@export var travelDistance = 512

var active = false

func _ready():
	if !Engine.is_editor_hint():
		# delete orb reference
		$OrbReference.queue_free()

func _process(_delta):
	if !Engine.is_editor_hint():
		# beam flashing (only flash if active)
		$Beam.visible = (!$Beam.visible and active)
	# use this to show a guide for the destination point
	else:
		$OrbReference.global_position = global_position+Vector2(0,-travelDistance)

func _physics_process(delta):
	if Engine.is_editor_hint():
		return false
	# run movement codes when the beam is active
	if active:
		Global.players[0].movement.y = -0.01 # set velocity.y to a negative so tail's tails rotate right
		var animator = $BeamAnimator
		var pl_animator: PlayerCharAnimationPlayer = Global.players[0].get_avatar().get_animator()
		# if the animator is playing the beam animation then move the player (after 1 second in the timeline has passed)
		if animator.current_animation == "Beam":
			if animator.current_animation_position > 1.0:
				pl_animator.play("roll")
				# shift x and y poses seperately so that the movement's not normalized
				Global.players[0].global_position.x = move_toward(Global.players[0].global_position.x,global_position.x,delta*60)
				Global.players[0].global_position.y -= delta*30
				# set physics object shift mode to allowTranslate
				Global.players[0].allowTranslate = true
		# only continue if the animator isn't playing
		elif !animator.is_playing():
			# shift up until player is above the travel distance
			if Global.players[0].global_position.y > global_position.y-travelDistance:
				Global.players[0].global_position.y -= 60*8*delta
				Global.players[0].visible = false
			# run ending sequence (play beam close then release the player)
			else:
				Global.players[0].visible = true
				# play closing animation
				animator.play("Close")
				# wait for animation to finish
				await animator.animation_finished
				active = false
				# set player state to air so they can play again
				Global.players[0].set_state(Global.players[0].STATES.AIR)
				# turn physics checking back on and restore collision mask
				Global.players[0].allowTranslate = false
				# give player a bit of velocity in that direction
				Global.players[0].movement.y = -30
				Global.players[0].airTimer = Global.players[0].defaultAirTime
				
		else: #shift player by default
			Global.players[0].global_position.y -= 30*delta

# called in the child orb using the player collision direction
func activateBeam():
	# check that the beam isn't already active so this doesn't cause a weird loop
	if !active:
		var player1 = Global.players[0]
		active = true
		$BeamAnimator.play("Beam")
		player1.set_state(Global.players[0].STATES.GIMMICK)
		player1.get_avatar().get_animator().play("idle")
		player1.set_ground_speed(60*4)
		player1.movement.x = 0
		player1.reset_air()
		
