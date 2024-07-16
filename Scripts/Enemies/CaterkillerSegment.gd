extends Hazard
var scattered = false
var movement = Vector2(0, -4)
@export var head: Node # assigned to the caterkiller's node in the scene

func _process(_delta):
	# if player array size isn't empty... scatter!!
	if (playerHit.size() > 0) and scattered == false:
		head.scatter_parts() # call to the head to scatter everything, since it has access to all the segments
	super(_delta) # still act like a hazard tho \:

func _physics_process(delta):
	# in a different function to make it consistent
	if scattered: # if scattered... bounce!
			movement.y += 0.21875
			position += movement # apply the speed
			if $FloorCast.is_colliding(): # if on floor...
				movement.y = -4 # boing.
			if $ScatterRemover.is_on_screen() == false: # segments free themselves AS SOON as they get offscreen
				queue_free()
