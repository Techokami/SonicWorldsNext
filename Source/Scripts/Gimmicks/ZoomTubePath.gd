extends Line2D

export var speed = 8;
export var animation = "Roll";
export var twoWay = false;
export var hitBoxSize = Vector2(4,4);

export var split = false;
export (int, 0, 100)var splitChance = 100;

var enteranceArea = Area2D.new();
var exitArea = Area2D.new();

# Active dir, determines the direction of pipe movement
var activeDir = 0;
# Player reference
var player = null;
# Current point in tube
var getPoint = 1;


func _ready():
	# generate hitboxes
	var hitbox = CollisionShape2D.new();
	var shape = RectangleShape2D.new();
	shape.extents = hitBoxSize;
	hitbox.set_shape(shape);
	enteranceArea.add_child(hitbox);
	
	# create enterance area
	add_child(enteranceArea);
	enteranceArea.collision_layer = 0;
	enteranceArea.collision_mask = 0;
	enteranceArea.set_collision_layer_bit(5,true)
	enteranceArea.connect("body_entered", self, "_on_hitbox_enter");
	enteranceArea.global_position = global_position+get_point_position(0);
	
	# check if two way
	if (twoWay):
		# create exit area collider
		exitArea.add_child(hitbox);
		add_child(exitArea);
		exitArea.collision_layer = enteranceArea.collision_layer;
		exitArea.collision_mask = enteranceArea.collision_mask;
		exitArea.connect("body_entered", self, "_on_hitbox_enter");
		exitArea.global_position = global_position+get_point_position(get_point_count()-1);

func _on_hitbox_enter(body):
	if ((body.currentState == body.STATES.ANIMATION) == split):
		randomize();
		var rng = rand_range(0,100);
		# run a random chance of a path split, or just continue if it is not a split
		if (rng <= splitChance || !split):
			body.set_state(body.STATES.ANIMATION);
			var animatorNode = body.stateList[body.STATES.ANIMATION];
			animatorNode.pipe = self;
			animatorNode.pipePoint = 1;
			animatorNode.pipeDirection = 1;
			body.global_position = global_position+get_point_position(0);
			body.movement = Vector2.ZERO;
