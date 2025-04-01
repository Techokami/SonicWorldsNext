extends BossBase

var deathTimer = 3
var dead = false

# you can use these to control behaviour
var phase = 0
var attackTimer = 0

@onready var getPose = [$LeftPoint.global_position,$RightPoint.global_position]
var currentPoint = 1
var Explosion = preload("res://Entities/Misc/GenericParticle.tscn")

var hoverOffset = 0

var animationPriority = ["default","move","laugh","hit","exploded"]

signal boss_over

func _ready():
	# move to the set currentPoint position before the boss starts (plus 128 pixels higher)
	global_position = getPose[currentPoint]+Vector2(0,-1)*128
	# run laugh function for every time the player gets hit
	connect("hit_player",Callable(self,"do_laugh"))

func _process(delta):
	# flame jet (only visible when moving)
	$EggMobile/EggmobileFlame.visible = !(velocity.x == 0 or $EggMobile/EggmobileFlame.visible)
	
	# flashing for the egg mobile 
	if flashTimer > 0:
		$EggMobile/EggFlash.visible = !$EggMobile/EggFlash.visible
	else:
		$EggMobile/EggFlash.visible = false
	
	# dead animation timer (default time is 3 seconds)
	if dead:
		# if above 0 then count down
		if deathTimer > 0:
			# count down
			deathTimer -= delta
			# if about to hit 1.5 seconds, set velocity downward
			if deathTimer > 1.5:
				if deathTimer-delta <= 1.5:
					set_animation("exploded",1.5)
					velocity.y = 200
			# if above 0.5 seconds left, move the momentum upwards until it's about -200
			elif deathTimer > 0.5:
				if velocity.y > -200:
					velocity.y -= 400*delta
				
				# if the next step is going to be below 0.5 seconds then stop moving
				if deathTimer-delta <= 0.5:
					velocity.y = 0
			
			# start running away once timer hits 0
			if deathTimer <= 0:
				velocity = Vector2(200,-25)
				scale.x = -abs(scale.x)
				boss_over.emit()

func _physics_process(delta):
	super(delta)
	# move boss
	global_position += velocity*delta
	# check if alive
	if active and !dead:
		# boss phase
		match(phase):
			0: # intro
				if global_position.y < getPose[currentPoint].y:
					velocity = ((getPose[currentPoint]-global_position)*60).limit_length(64)
				# move to center between positions
				elif global_position.x > (getPose[0].lerp(getPose[1],0.5)).x:
					velocity = ((getPose[0].lerp(getPose[1],0.5)-global_position)*60).limit_length(64)
				elif attackTimer < 2:
					# do laugh
					if flashTimer <= 0:
						set_animation("laugh")
					velocity = Vector2.ZERO
					attackTimer += delta
				else: # end intro
					phase = 1
					currentPoint = 0
				
			1: # main attack
				
				# reset hover position
				global_position.y = global_position.y-hoverOffset
				# change the hover
				hoverOffset = move_toward(hoverOffset,cos(Global.levelTime*4)*4,delta*10)
				# move
				var getPosition = (getPose[currentPoint]-global_position)*60
				velocity = getPosition.limit_length(64)
				# now move the hover position back
				global_position.y = global_position.y+hoverOffset
				
				# set scale to face the current point position
				if is_equal_approx(global_position.x,getPose[currentPoint].x):
					scale.x = abs(scale.x)*remap(currentPoint,0,1,-1,1)
				
				# increase attack timer
				attackTimer += delta
				
				# switch positions after 5 seconds
				if attackTimer >= 5:
					currentPoint = 1-currentPoint
					attackTimer = 0
	
	# default reactions (use animation time to avoid running this every frame)
	if $AnimationTime.is_stopped():
		# if moving, then run move animation
		if velocity.x != 0:
			set_animation("move")
		# check if dead, this can cause a conflict where the idle animation would play when it shouldn't
		elif !dead:
			set_animation("default")
	# only run hit if flash timer is above 0
	if flashTimer > 0:
		set_animation("hit",flashTimer)
	

# animation to play, time is how long the animation should play for until it stops
func set_animation(animation = "default", time = 0.0):
	# check that the animation exists in the animationPriority list
	if animationPriority.has(animation):
		# if the animation exists then compare the position
		var animID = animationPriority.find(animation)
		var currentAnimID = animationPriority.find($EggMobile/Robotnik.animation)
		
		# if the new animation ID is higher then the current one or the animation time isn't running then play the animation
		if animID > currentAnimID or $AnimationTime.is_stopped():
			$EggMobile/Robotnik.play(animation)
			$AnimationTime.start(time)
	# if there is no priority set then just run the new animation
	else:
		$EggMobile/Robotnik.play(animation)
		$AnimationTime.start(time)

# boss defeated
func _on_boss_defeated():
	# set dead to true
	dead = true
	# hit animation for 1.5 seconds (see the dead section in _process)
	set_animation("hit",1.5)
	# set velocity to 0 to prevent moving
	velocity = Vector2.ZERO
	# star the smoke timer
	$SmokeTimer.start(0.1)

# do a laugh for 1 second
func do_laugh():
	set_animation("laugh",1)

func _on_SmokeTimer_timeout():
	# check that deathtimer's still going and that we are actually dead
	if dead and deathTimer > 1.5:
		# play explosion sound
		$Explode.play()
		# spawn exposion particles
		var expl = Explosion.instantiate()
		# set animation
		expl.play("BossExplosion")
		expl.z_index = 10
		# add object
		get_parent().add_child(expl)
		# set position reletive to us
		expl.global_position = global_position+Vector2(randf_range(-32,32),randf_range(-32,32))
