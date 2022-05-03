extends "res://Scripts/Player/State.gd"

var path = null
var offset = 0
var pipe = null
var pipePoint = 0
var pipeDirection = 1

func _process(delta):
	if (path != null):
		var pathCurve = path.path.curve
		
		var id = min((pathCurve.get_point_count()-1)*(offset/pathCurve.get_baked_length()),pathCurve.get_point_count()-1)
		parent.global_position = path.global_position+pathCurve.interpolate(floor(id),fmod(id,1)).rotated(path.rotation)
		var relativeOffset = offset/pathCurve.get_baked_length()*pathCurve.get_point_count()
		
		offset += parent.movement.length()*delta
		
		var frames = (path.endFrame-path.startFrame+1)*path.animLoops
		
		parent.sprite.frame = path.endFrame+1-fmod(((offset/pathCurve.get_baked_length()))*frames,frames/path.animLoops)
		
		# Free the player
		if (offset/pathCurve.get_baked_length() >= 1):
			parent.set_state(parent.STATES.NORMAL)
			parent.translate = false
			offset = 0
			parent.movement = (pathCurve.get_point_position(pathCurve.get_point_count()-1)-pathCurve.get_point_position(pathCurve.get_point_count()-2)).normalized()*parent.movement.length()
	elif (pipe != null):
		
		# get next pipe point
		var point = pipe.global_position+pipe.get_point_position(pipePoint)
		# set movement
		parent.movement = ((point-parent.global_position).clamped(pipe.speed))/delta
		parent.translate = true
		
		if (parent.global_position.distance_to(point) < pipe.speed):
			if (pipePoint < pipe.get_point_count()-1):
				parent.global_position = point
				parent.movement = Vector2.ZERO
				pipePoint += 1
			else:
				# release the player if no other point can be found
				parent.movement = (point-(pipe.global_position+pipe.get_point_position(pipePoint-1))).normalized()*pipe.speed*Global.originalFPS
				parent.set_state(parent.STATES.ROLL,parent.HITBOXESSONIC.ROLL)
				parent.translate = false
				parent.sfx[3].play()
