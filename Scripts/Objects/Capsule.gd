extends StaticBody2D
var getCam = null

@onready var screenXSize = get_viewport_rect().size.x

var Animal = preload("res://Entities/Misc/Animal.tscn")
var animalTrackers = []
var checkAnimals = false
var timerActive = false
var timer = 180.0/60.0

func _physics_process(delta):
	
	
	if timerActive and timer > 0:
			# every 8/60 steps spawn an animal in the animal ground with an alarm of 12/60
			if wrapf(timer,0,8.0/60.0) < wrapf(timer-delta,0,8.0/60.0):
				var animal = Animal.instantiate()
				# set animal sprite
				animal.animal = Global.animals[round(randf())]
				# deactivate animal to stop movement
				animal.active = false
				# random directions
				animal.forceDirection = false
				get_parent().add_child(animal)
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
			# temporarily set stage clear to 0 so that the music can play
			Global.stageClearPhase = 0
			Global.stage_clear()
			# set stage clear to 3 to continue playing the level clear phase
			Global.stageClearPhase = 3
			checkAnimals = false


func activate():
	# check if to clear level
	if Global.stageClearPhase == 0:
		$Animator.play("Open")
		# set global stage clear phase to 1, 1 is used to stop the timer (see HUD script)
		Global.stageClearPhase = 1
		
		# set player camera limits
		for i in Global.players:
			# Camera limit set
			i.limitLeft = global_position.x -screenXSize/2
			i.limitRight = global_position.x +screenXSize/2



func spawn_animals():
	# create animals
	for i in range(8):
		var animal = Animal.instantiate()
		# set animal sprite
		animal.animal = Global.animals[round(randf())]
		# deactivate animal to stop movement
		animal.active = false
		# random directions
		animal.forceDirection = false
		get_parent().add_child(animal)
		animalTrackers.append(animal)
		# set animal position, starting from -28 on the x position and increasing by 8 per animal
		animal.global_position = global_position+Vector2(-28+(7*i),0)
		# set alarms, starting at 154.0/60.0 (converting the original timer) and counting down by 8.0/60.0 for each animal
		animal.get_node("ActivationTimer").start((154.0/60.0)-((8.0/60.0)*i))
	
	checkAnimals = true
	timerActive = true
	
