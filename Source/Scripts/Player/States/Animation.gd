extends "res://Scripts/Player/State.gd"

# animation state

# this state is meant to be used generally to play animations

var offset = 0
var path = null
var pipe = null
var pipePoint = 0
var pipeDirection = 1

func _process(delta):
	# this state can be used for several purposes, pipe logic is a bit more complicated so I built some pipe following code here
	if (pipe != null):
		# get next pipe point
		var point = pipe.global_position+pipe.get_point_position(pipePoint)
		# set movement
		parent.movement = parent.global_position.direction_to(point)
		parent.global_position = parent.global_position.move_toward(point,pipe.speed*60*delta)
		parent.translate = true
		
		# if nearing the end of the current path pipe check if to end or go to next pipe path
		if parent.global_position.distance_to(point) < pipe.speed:
			# check if we're at the end of the path
			if pipePoint < pipe.get_point_count()-1:
				parent.global_position = point
				pipePoint += 1
				point = pipe.global_position+pipe.get_point_position(pipePoint)
			else:
				# release the player if no other point can be found
				parent.set_state(parent.STATES.ROLL)
				parent.movement = (point-(pipe.global_position+pipe.get_point_position(pipePoint-1))).normalized()*pipe.speed*60.0
				parent.global_position = point
				parent.translate = false
				parent.sfx[3].play()
				pipe = null
