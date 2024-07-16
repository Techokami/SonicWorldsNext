extends EnemyBase
@onready var segments = [self, $Segment1, $Segment2, $Segment3]
var scattered = false # same as segments.
var verticalspeed = -4 # specifically for scattering
var currentState = 0 # see below

# Movement States, each item corresponds to segments in the array above, including the head.
# State 0 is when a pose is being held by the Caterkiller, so all the values are 0
# State 1 is for Scrunching Up
# State 2 is for Stretching Out
# the individual elements are x speeds, y movement is handled by the script
var stateInfo = [
	[0, 0, 0, 0],
	[0, 0.25, 0.5, 0.75],
	[0.75, 0.5, 0.25, 0]
]
# is each segment on the ground? this is important since turning around is also based on the sensor not detecting anything
var segmentgroundstate = [false, false, false, false]

# state animation, even though there's an AnimationPlayer node here it's kinda hacky and results in some inconsistent behavior to do it that way.
var stateTimer: int = 8 # timer for each state to function
var stateOrderIndex = 0 # the index to switch states in the correct order
var stateOrder = [0,1,0,2] # Pose, scruch, pose, stretch, repeat.


func _ready():
	# move segments out of this object, since they move rather independent of eachother and the main head, even if the head controls them
	unparent_segment($Segment3)
	unparent_segment($Segment2)
	unparent_segment($Segment1)

# function used for each segment freeing themselves from the parent's position
func unparent_segment(child):
	var oldpos = child.global_position
	remove_child(child)
	get_parent().add_child.call_deferred(child) # entity space is setting up their children during this _ready so... gotta be this
	child.global_position = oldpos # move the child back

func _physics_process(delta):
	if scattered: # if scattered... bounce!
		verticalspeed += 0.21875
		position += Vector2(-2*scale.x, verticalspeed) # x velocity is hardcoded
		if $FloorCast.is_colliding(): # if on floor...
			verticalspeed = -4 # boing.
		if $ScatterRemover.is_on_screen() == false: # segments free themselves AS SOON as they get offscreen
			queue_free()
	else:
		for i in segments.size():
			segments[i].position.x -= stateInfo[currentState][i]*segments[i].scale.x # move according to the state and the facing direction
			# align to the floors
			segments[i].get_node("FloorCast").force_raycast_update()
			if segments[i].get_node("FloorCast").is_colliding() and segments[i].get_node("FloorCast").get_collision_point().y - segments[i].global_position.y >= -8: # is the wall too high as well?
				segments[i].global_position.y = segments[i].get_node("FloorCast").get_collision_point().y - 10 # add to the bottom of the sprite, change this if the sprite changes size
			elif segmentgroundstate[i] == true: # if previously grounded but now not, turn.
				segments[i].scale.x *= -1
			segmentgroundstate[i] = segments[i].get_node("FloorCast").is_colliding() # set ground state
		# vertical animation is a table, but i'm not gonna do that, i'm just going to move this a consistent amount
		# the original table seemed to have some amount of easing or whatever, since it makes four 0s to start and three 7s at the end... but idk.
		if currentState == 1: # scrunch UP
			$Head.position.y -= 0.5
			segments[2].get_node("Sprite").position.y -= 0.5
		if currentState == 2: # stretch DOWN
			$Head.position.y += 0.5
			segments[2].get_node("Sprite").position.y += 0.5
		# The state system is supposed to help animate the Caterkiller properly, so here it is.
		stateTimer -= 1
		if stateTimer == 0: # change the index
			stateOrderIndex += 1
			stateOrderIndex %= stateOrder.size() # loop around
			currentState = stateOrder[stateOrderIndex] # set the state
			match currentState: # set the timer and jaw frame
				0:
					stateTimer = 8
				1:
					stateTimer = 16
					$Head.frame = 1 # open jaw on scrunch
				2: 
					stateTimer = 16
					$Head.frame = 0 # close jaw

func destroy():
	super() # still actually destroy it
	if scattered == false: # all segments are completley independent of eachother when scattered.
		for i in segments: # get rid of attached segments
			if i != self:
				i.queue_free()

func scatter_parts():
	$Head.position.y = 0 # sprite offsets are going to look funny when using the same collisions
	segments[2].get_node("Sprite").position.y = 0
	for i in segments: # make 'em start bouncing!
		i.scattered = true
	# give each segment their unique speed
	# the head is hardcoded to use the correct speed at -2 every frame
	segments[1].movement.x = -1.5*segments[1].scale.x
	segments[2].movement.x = 1.5*segments[2].scale.x
	segments[3].movement.x = 2*segments[3].scale.x

func _process(_delta):
	# if player array size isn't empty... scatter!!
	if (playerHit.size() > 0) and scattered == false:
		scatter_parts() # this IS the head, this is the only difference in this function as the rest is just the EnemyBase.
	super(_delta) # still act like an enemy tho \:
