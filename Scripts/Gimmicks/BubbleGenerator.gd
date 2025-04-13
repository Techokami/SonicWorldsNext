extends Node2D

# Note: big bubble has been adjusted and does not follow the original games behaviour

var bubbleTimer = 0
var bigBubbleTimer = 10
var Bubble = preload("res://Entities/Misc/Bubbles.tscn")

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
			var bubble = Bubble.instantiate()
			# pick either 0 or 1 for the bubble type
			bubble.bubbleType = int(round(randf()))
			add_child(bubble)
			bubble.global_position = global_position
		
		# Big bubble generator
		if bigBubbleTimer > 0:
			bigBubbleTimer -= delta
		else:
			# if timer runs out generate bubble and reset timer to 10 seconds
			bigBubbleTimer += 10.0
			var bubble = Bubble.instantiate()
			# set type to 2 for big bubbles
			bubble.bubbleType = 2
			add_child(bubble)
			bubble.global_position = global_position
		
