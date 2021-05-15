extends "res://Scripts/Player/State.gd"


func _physics_process(delta):
	parent.animator.play("Hurt");
	# gravity
	parent.velocity.y += 0.1875/delta;
	
	if (parent.ground):
		parent.velocity.x = 0;
		parent.set_state(parent.STATES.NORMAL);
		parent.invTime = 120;
