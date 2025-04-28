extends Line2D

@export var speed = 8
@export var animation = "roll"
@export var twoWay = false
@export var hitBoxSize = Vector2(4,4)

@export var split = false
@export_range(0, 100)var splitChance = 100

var enteranceArea = Area2D.new()
var exitArea = Area2D.new()

# Active dir, determines the direction of pipe movement
var activeDir = 0
# Player reference
var player = null
# Current point in tube
var getPoint = 1


func _ready():
	# generate hitboxes
	var hitbox = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = hitBoxSize
	hitbox.set_shape(shape)
	enteranceArea.add_child(hitbox)
	
	# create enterance area
	add_child(enteranceArea)
	enteranceArea.collision_layer = 0
	enteranceArea.collision_mask = 0
	enteranceArea.set_collision_mask_value(13,true)
	enteranceArea.connect("body_entered",Callable(self,"_on_hitbox_enter"))
	enteranceArea.global_position = global_position+get_point_position(0)
	
	# check if two way
	if (twoWay):
		# create exit area collider
		exitArea.add_child(hitbox)
		add_child(exitArea)
		exitArea.collision_layer = enteranceArea.collision_layer
		exitArea.collision_mask = enteranceArea.collision_mask
		exitArea.connect("body_entered",Callable(self,"_on_hitbox_enter"))
		exitArea.global_position = global_position+get_point_position(get_point_count()-1)

func _on_hitbox_enter(body: PlayerChar):
	if (body.get_state() == PlayerChar.STATES.ANIMATION) == split:
		randomize()
		var rng = randf_range(0,100)
		var player_state = body.get_state_object(PlayerChar.STATES.ANIMATION)
		# run a random chance of a path split, or just continue if it is not a split
		if (rng <= splitChance or !split) and player_state.pipe != self:
			if body.get_state() != PlayerChar.STATES.ANIMATION:
				body.sfx[1].play()
				
			# TODO This seems totally unnoticeable. Also I don't get it.
			# DW's note: Because we did the wacky condition at the beginning of this function, we
			# might have gotten here with the player's state not being ANIMATION, in which case
			# we need to make the player's state ANIMATION. Otherwise it wouldn't do any of the
			# zoom tube stuff since that is mostly handled by the ANIMATION state.
			body.set_state(body.STATES.ANIMATION,Vector2(2,2))
			player_state.pipe = self
			player_state.pipePoint = 1
			player_state.pipeDirection = 1
			body.animator.play("roll")
			body.groundSpeed = 60*4
			body.global_position = global_position+get_point_position(0)
			body.movement = Vector2.ZERO
