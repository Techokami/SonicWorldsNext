extends Node2D

# Note: big bubble has been adjusted and does not follow the original games behaviour

var bubbleTimer = 0
var bigBubbleTimer = 10

func _process(delta):
	if Global.waterLevel != null:
		visible = global_position.y > Global.waterLevel
	else:
		visible = false
	
	# Since visibility is tied to water level, bubbles only generate when below water level
	if visible:
		if bubbleTimer > 0:
			bubbleTimer -= delta
		else:
			# if timer runs out, set to a random number between 0 and 3 and generate bubble
			bubbleTimer += randf()*3.0
			Bubble.create_small_or_medium_bubble(self, global_position)
		
		# Big bubble generator
		if bigBubbleTimer > 0:
			bigBubbleTimer -= delta
		else:
			# if timer runs out generate bubble and reset timer to 10 seconds
			bigBubbleTimer += 10.0
			Bubble.create_big_bubble(self, global_position)
		
