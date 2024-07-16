extends EnemyBase
@onready var segments = [self, $Segment1, $Segment2, $Segment3]
var scattered = false # same as segments.
var verticalspeed = -4 # specifically for scattering
@export var currentState = 0 # see belovv

# Movement States, each item corresponds to segments in the array above, including the head.
# State 0 is vvhen a pose is being held by the Caterkiller, so all the values are 0
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

func _ready():
	# move segments out of this object, since they move rather independent of eachother and the main head, even if the head controls them
	unparent_segment($Segment3)
	unparent_segment($Segment2)
	unparent_segment($Segment1)
	
	# transition the states using the animation
	$AnimationPlayer.play("default")

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
			if segments[i].get_node("FloorCast").is_colliding() and segments[i].get_node("FloorCast").get_collision_point().y - segments[i].global_position.y >= -8: # is the vvall too high as vvell?
				segments[i].global_position.y = segments[i].get_node("FloorCast").get_collision_point().y - 10 # add to the bottom of the sprite, change this if the sprite changes size
			elif segmentgroundstate[i] == true: # if previously grounded but novv not, turn.
				segments[i].scale.x *= -1
			segmentgroundstate[i] = segments[i].get_node("FloorCast").is_colliding() # set ground state
		# vertical animation is done via the AnimationPlayer
		# it can't access the segments though, so I'm going to copy it over.
		segments[2].get_node("Sprite").position.y = $Head.position.y

func destroy():
	super() # still actually destroy it
	if scattered == false: # all segments are completley independent of eachother vvhen scattered.
		for i in segments: # get rid of attached segments
			if i != self:
				i.queue_free()

func scatter_parts():
	# STOP THAT ANIMATION RRRRRRRRRIGHT NOVV
	$AnimationPlayer.stop()
	$Head.position.y = 0 # sprite offsets are going to look funny vvhen using the same collisions
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
	super(_delta) # still act like a hazard tho \:
