extends "res://Scripts/Player/State.gd"


func _input(event):
	if (parent.playerControl != 0):
		if (event.is_action_pressed("gm_action")):
			parent.animator.play("Spindash");
			parent.sfx[2].play();
			if (parent.spindashPower < 1):
				parent.spindashPower = min(parent.spindashTap+parent.spindashPower,1);
			parent.sfx[2].pitch_scale = 1+(parent.spindashPower*0.5);
		
func _process(delta):
	# release
	if (parent.inputs[parent.INPUTS.YINPUT] <= 0):
		parent.velocity.x = (parent.minSpindash+((parent.spindash-parent.minSpindash)*parent.spindashPower))*parent.direction;
		parent.sfx[3].play();
		parent.sfx[2].stop();
		parent.sfx[2].pitch_scale = 1;
		parent.set_state(parent.STATES.ROLL);
		
		parent.animator.play("Roll");
	if (parent.spindashPower > 0):
		parent.spindashPower = max(0,parent.spindashPower-(delta*0.25));
		
