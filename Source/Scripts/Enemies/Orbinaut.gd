extends "res://Scripts/Enemies/EnemyBase.gd"

@export var orbs = 4;
@export var speed = -100;
@export var distance = 16;
var spinOffset = 0;

@onready var orbList = [get_node("Orb")];

func _ready():
	velocity.x = -10;
	for i in range(orbs-1):
		var newOrb = $Orb.duplicate();
		add_child(newOrb);
		orbList.append(newOrb);

func _physics_process(delta):
	spinOffset += speed*delta;
	for i in range(orbList.size()):
		var getOrb = orbList[i];
		getOrb.position = (Vector2.RIGHT*distance).rotated(deg2rad(spinOffset+((360/orbs)*i)));
