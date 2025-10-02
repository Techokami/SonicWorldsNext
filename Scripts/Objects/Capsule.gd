extends StaticBody2D
var getCam = null

@onready var screenXSize = get_viewport_rect().size.x

var animalTrackers = []
var checkAnimals = false
var timerActive = false
var timer = 180.0/60.0

func _physics_process(delta):
	
	
	if timerActive and timer > 0:
			# every 8/60 steps spawn an animal in the animal ground with an alarm of 12/60
			if wrapf(timer,0,8.0/60.0) < wrapf(timer-delta,0,8.0/60.0):
				# set a random position within a (-20,20) range
				var pos: Vector2 = global_position+Vector2(randf_range(-20.0,20.0),0)
				# set alarms, starting at 12.0/60.0 (converting the original timer)
				const time: float = 12.0/60.0
				var animal: Animal = Animal.create(get_parent(), pos, time, false)
				animalTrackers.append(animal)
			
			timer -= delta
		
	# after flickies are gone, set stage clear phase to SCORE_TALLY
	# (GOALPOST_SPIN_END is for running off screen, see GoalPost.gd)
	if checkAnimals and animalTrackers.size() > 0:
		
		for i in animalTrackers:
			if !is_instance_valid(i):
				animalTrackers.erase(i)
		
		if animalTrackers.is_empty():
			# temporarily set stage clear to NOT_STARTED so that the music can play
			Global.reset_stage_clear_phase()
			Global.stage_clear()
			# set stage clear to SCORE_TALLY to continue playing the level clear phase
			Global.set_stage_clear_phase(Global.STAGE_CLEAR_PHASES.SCORE_TALLY)
			checkAnimals = false


func activate():
	# check if to clear level
	if !Global.is_in_any_stage_clear_phase():
		$Animator.play("Open")
		$Explode.play()
		# set global stage clear phase to START, this is used to stop the timer (see HUD script)
		Global.set_stage_clear_phase(Global.STAGE_CLEAR_PHASES.STARTED)
		
		# set player camera limits
		for i in Global.players:
			# Camera limit set
			i.camera.target_limit_left = global_position.x-screenXSize/2.0
			i.camera.target_limit_right = global_position.x+screenXSize/2.0



func spawn_animals():
	# create animals
	for i in range(8):
		# set animal position, starting from -28 on the x position and increasing by 7 per animal
		var pos: Vector2 = global_position+Vector2(7.0*(i-4), 0.0)
		# set alarms, starting at 154.0/60.0 (converting the original timer) and counting down by 8.0/60.0 for each animal
		var time: float = float(154-8*i)/60.0
		var animal: Animal = Animal.create(get_parent(), pos, time, false)
		animalTrackers.append(animal)
	
	checkAnimals = true
	timerActive = true
	
