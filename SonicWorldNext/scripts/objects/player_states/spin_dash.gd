extends "res://scripts/objects/player_states/state.gd"

func _input(event):
	if (parent.playerControl != 0):
		if (event.is_action_pressed("gm_action")):
			parent.sprite.play("spindash");
			parent.sprite.frame = 0;
			#parent.sfx[2].play();
			if (parent.spindashPower < 8):
				parent.spindashPower = min(parent.spindashPower+2,8);
			#parent.sfx[2].pitch_scale = 1.0+((float(parent.spindashPower)/8.0)*0.5);
		
func _process(delta):
	# release
	if (parent.inputs[parent.INPUTS.YINPUT] <= 0):
		parent.movement.x = (8+(floor(parent.spindashPower) / 2))*60*parent.direction;
		#parent.sfx[3].play();
		#parent.sfx[2].stop();
		#parent.sfx[2].pitch_scale = 1;
		parent.set_state(parent.STATES.ROLL);
		
		parent.sprite.play("roll");
	parent.spindashPower -= ((parent.spindashPower / 0.125) / (256))*60*delta;
		
