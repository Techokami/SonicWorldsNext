extends Node2D

var activated = false

func _process(delta):
	
	$Sprite.offset.y = move_toward($Sprite.offset.y,-64*float(!activated),delta*60*8)

func activate():
	if (activated):
		return
		
	$BigFan.play()
	activated = true

func deactivate():
	if (!activated):
		return
		
	$BigFan.stop()
	activated = false
