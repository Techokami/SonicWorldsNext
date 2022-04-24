extends Sprite
var active = false

func _physics_process(delta):
	if Global.players[0].global_position.x > global_position.x && Global.players[0].global_position.y <= global_position.y && !active:
		$Animator.play("Spinner")
		$Animator.queue("Sonic")
		$GoalPost.play()
		active = true
		
