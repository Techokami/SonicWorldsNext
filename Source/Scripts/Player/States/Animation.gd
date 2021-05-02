extends "res://Scripts/Player/State.gd"

var path = null;
var offset = 0;

func _process(delta):
	if (path != null):
		var pathCurve = path.path.curve;
		
		var id = min((pathCurve.get_point_count()-1)*(offset/pathCurve.get_baked_length()),pathCurve.get_point_count()-1);
		parent.global_position = path.global_position+pathCurve.interpolate(floor(id),fmod(id,1)).rotated(path.rotation);
		var relativeOffset = offset/pathCurve.get_baked_length()*pathCurve.get_point_count();
		
		# point to point
		#if (relativeOffset < 1):
		#	parent.global_position = path.global_position+pathCurve.interpolate_baked(offset);
		
		offset += parent.velocity.length()*delta;
		
		
		
		var frames = (path.endFrame-path.startFrame+1)*path.animLoops;
		
		parent.sprite.frame = path.endFrame+1-fmod(((offset/pathCurve.get_baked_length()))*frames,frames/path.animLoops);
		
		# Free the player
		if (offset/pathCurve.get_baked_length() >= 1):
			parent.set_state(parent.STATES.NORMAL);
			offset = 0;
			parent.velocity = (pathCurve.get_point_position(pathCurve.get_point_count()-1)-pathCurve.get_point_position(pathCurve.get_point_count()-2)).normalized()*parent.velocity.length();
