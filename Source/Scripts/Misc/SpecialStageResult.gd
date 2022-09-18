extends Node2D

var activated = false

func _ready():
	# set stage text label to the current stage
	$HUD/Stage.text = "Stage "+str(Global.specialStageID+1)
	# cycle through emeralds on the hud
	for i in $HUD/ColorRect/HBoxContainer.get_child_count():
		# compare the bit value of Global.emeralds using a bitwise operation
		# if the emerald isn't collected then hide it
		$HUD/ColorRect/HBoxContainer.get_child(i).get_child(0).visible = (Global.emeralds & (1 << i))

func _input(event):
	if !activated:
		# set to win
		if event.is_action_pressed("gm_action"):
			# set binary bit of current emerald (using the special stage ID)
			Global.emeralds = Global.emeralds | (1 << Global.specialStageID)
			activated = true
			# play emerald jingle
			$Emerald.play()
			# show current stages emerald
			$HUD/ColorRect/HBoxContainer.get_child(Global.specialStageID).get_child(0).visible = true
			yield($Emerald,"finished")
			next_stage()
			Global.main.change_scene(null,"FadeOut","","SetAdd",1,true,false)
			
			
		if event.is_action_pressed("gm_action2"):
			activated = true
			next_stage()
			Global.main.change_scene(null,"FadeOut","","SetAdd",1,true,false)


func next_stage():
	# done a loop ensures that the while loop executes at least once
	var doneALoop = false
	# if emeralds less then 127 (all 7 emeralds collected in binary)
	# check that there isn't already an emerald collected on current stage
	while Global.emeralds < 127 and (Global.emeralds & (1 << Global.specialStageID) or !doneALoop):
		Global.specialStageID = wrapi(Global.specialStageID+1,0,7)
		doneALoop = true
