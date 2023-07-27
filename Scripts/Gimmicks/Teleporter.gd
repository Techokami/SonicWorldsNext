@tool
extends Node2D

@export var travelDistance = 512

var active = false

func _ready():
	if !Engine.is_editor_hint():
		# delete orb reference
		$OrbReference.queue_free()

func _process(delta):
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
		# if the animator is playing the beam animation then move the player (after 1 second in the timeline has passed)
		if animator.current_animation == "Beam":
			if animator.current_animation_position > 1.0:
				Global.players[0].animator.play("roll")
				# shift x and y poses seperately so that the movement's not normalized
				Global.players[0].global_position.x = move_toward(Global.players[0].global_position.x,global_position.x,delta*60)
				Global.players[0].global_position.y -= delta*30
				# set physics object shift mode to translate
				Global.players[0].translate = true
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
				Global.players[0].translate = false
				# give player a bit of velocity in that direction
				Global.players[0].movement.y = -30
				
		else: #shift player by default
			Global.players[0].global_position.y -= 30*delta

# called in the child orb using the player collision direction
func activateBeam():
	# check that the beam isn't already active so this doesn't cause a weird loop
	if !active:
		active = true
		$BeamAnimator.play("Beam")
		Global.players[0].set_state(Global.players[0].STATES.ANIMATION)
		Global.players[0].animator.play("idle")
		Global.players[0].groundSpeed = 60*4
		Global.players[0].movement.x = 0
