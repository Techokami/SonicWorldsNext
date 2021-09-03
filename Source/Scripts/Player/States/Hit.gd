extends "res://Scripts/Player/State.gd"


func _physics_process(delta):
	parent.sprite.play("hurt");
	# gravity
	parent.velocity.y += 0.1875/delta;
	
	if (parent.ground):
		parent.velocity.x = 0;
		parent.set_state(parent.STATES.NORMAL);
		parent.invTime = 120;
