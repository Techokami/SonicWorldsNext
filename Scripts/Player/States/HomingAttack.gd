class_name HomingAttackState extends PlayerState

# Tracks which targetable the homing attack is directed at
var cur_target: Targetable = null

# Tracks where the player was in the previous frame -- used to check forceful exit conditions
var previous_position := Vector2()

# The direction that the homing attack was going in the previous frame -- used to check forceful
# exit conditions
var previous_direction = Vector2()

# Tracks how long the homing attack can remain active without kicking the player out.
# This serves as a fail safe against the homing attack lasting too long.
var force_cancel_timer := AUTO_CANCEL_TIMEOUT

## This is the speed that the homing attack moves at in pixels per second (equivalent to 10px per
## frame at 60 hz)
@export var HOMING_ATTACK_SPEED := 600 # pixels per second

## If the angle that the player has to seek to changes more than this angle, we are just going to
## cancel the homing attack. This prevents the player from whipping back in extreme cases
@export var AUTO_CANCEL_ANGLE_CHANGE := 2.0 * PI / 3.0

## If the player's homing attack falls below this speed (in pixels per second, equivalent to 3.33px
## per frame at 60hz), they will be kicked out of homing attack. This will happen if the player gets
## snagged on a wall or a similar object.
@export var AUTO_CANCEL_SPEED := 200 # pixels per second

## If the player's homing attack lasts longer than this amount of time (in seconds), it will
## automatically be cancelled.
@export var AUTO_CANCEL_TIMEOUT := 2.0

func set_target(new_target: Targetable):
	
	cur_target = new_target
	force_cancel_timer = AUTO_CANCEL_TIMEOUT
	previous_position = parent.global_position
	previous_direction = (cur_target.global_position - parent.global_position).normalized()
	parent.movement = previous_direction * HOMING_ATTACK_SPEED

func state_player_bounce(_source: Node2D, bounce_mode: PlayerChar.BOUNCE_MODES):
	# The main things bouncing off an enemy during a homing attack needs to do is reset the player's
	# state to a normal jump, change their animation to rolling, reset aerial abilities / status,
	# launch them upwards
	parent.set_state(PlayerChar.STATES.AIR)
	
	# We bounce upwards if bouncing normally (like off an enemy, maybe some kinds of destructibles)
	if bounce_mode == PlayerChar.BOUNCE_MODES.NORMAL:
		print("homing bounce normal")
		parent.movement.x = 0
		parent.movement.y = -6.5*60
	elif bounce_mode == PlayerChar.BOUNCE_MODES.BOSS:
		print("homing bounce boss")
		parent.movement.x *= -1
		parent.movement.y *= -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	pass # Replace with function body.

func state_activated():
	pass

func state_process(_delta: float) -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func state_physics_process(delta: float) -> void:
	
	# cur_target being null shouldn't be possible unless someone screws up big time, but the target
	# might become canceled if say... Tails pops it while you are homing or something like that.
	if cur_target == null or not is_instance_valid(cur_target):
		parent.set_state(PlayerChar.STATES.NORMAL)
		return
	
	# Force end of homing attack if we are stuck in it for more than the set number of seconds
	force_cancel_timer -= delta
	if force_cancel_timer <= 0:
		parent.set_state(PlayerChar.STATES.NORMAL)
		return
		
	# Force end if the effective speed isn't above the auto cancel speed
	if (parent.global_position - previous_position).length() / delta < AUTO_CANCEL_SPEED:
		parent.set_state(PlayerChar.STATES.NORMAL)
		return
	
	# Force end if we touch ground
	if parent.is_on_ground():
		parent.set_state(PlayerChar.STATES.NORMAL)
		return
		
	# Direction to the target
	var to_target := (cur_target.global_position - parent.global_position).normalized()
	
	# Flag end for next frame if this translation will push us through the target
	#print(to_target.angle_to(previous_direction))
	#if (abs(to_target.angle_to(previous_direction)) > AUTO_CANCEL_ANGLE_CHANGE):
	#	parent.set_state(PlayerChar.STATES.NORMAL)
	#	return
	
	previous_direction = to_target
	previous_position = parent.global_position
	parent.movement = to_target * HOMING_ATTACK_SPEED

func state_exit():
	cur_target = null
