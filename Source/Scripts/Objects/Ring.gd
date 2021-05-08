extends Node2D



func _on_Hitbox_body_entered(body):
	body.rings += 1;
	print(body.rings);
	queue_free();
