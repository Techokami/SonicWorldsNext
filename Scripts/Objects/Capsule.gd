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
				var animal: Animal = Animal.create(get_parent(), global_position, false, false)
				animalTrackers.append(animal)
				# set animal position, starting from -28 on the x position and increasing by 8 per animal
				animal.global_position = global_position+Vector2(randf_range(-20,20),0)
				# set alarms, starting at 12.0/60.0 (converting the original timer)
				animal.get_node("ActivationTimer").start(12.0/60.0)
			
			timer -= delta
		
	# after flickes are gone, set stage clear to 3 (2's for running off screen, see the goal post)
	if checkAnimals and animalTrackers.size() > 0:
		
		for i in animalTrackers:
			if !is_instance_valid(i):
				animalTrackers.erase(i)
		
		if animalTrackers.size() <= 0:
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
			i.limitLeft = global_position.x -screenXSize/2
			i.limitRight = global_position.x +screenXSize/2



func spawn_animals():
	# create animals
	for i in range(8):
		var animal: Animal = Animal.create(get_parent(), global_position, false, false)
		animalTrackers.append(animal)
		# set animal position, starting from -28 on the x position and increasing by 8 per animal
		animal.global_position = global_position+Vector2(-28+(7*i),0)
		# set alarms, starting at 154.0/60.0 (converting the original timer) and counting down by 8.0/60.0 for each animal
		animal.get_node("ActivationTimer").start((154.0/60.0)-((8.0/60.0)*i))
	
	checkAnimals = true
	timerActive = true
	
