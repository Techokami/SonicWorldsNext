extends Node2D

@export var starpostID = 0
var active = false



func _on_hitbox_body_entered(body):
	if !active:
		$Animator.play("Activate")
		active = true
		$Starpost2.play()
	
