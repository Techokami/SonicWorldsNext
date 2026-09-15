extends EnemyProjectileBase

func _process(delta: float) -> void:
	velocity.y += (0.09375/GlobalFunctions.div_by_delta(delta))
	super(delta)
