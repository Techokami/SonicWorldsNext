extends EnemyBase

## Speed to climb at.
@export var move_speed: float = 60.0
## Values copied from Sonic 2. Make sure these value equal out t 0 if you change them.
@export var climb_positions: Array[float] = [
	-32,24,-16,40,-32,16
	]
@export var climb_pause_time: float = 0.5

@onready var animator: AnimationPlayer = $AnimationPlayer

## Todo
var coconut_scene: PackedScene = preload("res://Entities/Enemies/Projectiles/EnemyProjectileBase.tscn")

enum STATE{IDLE,CLIMB,THROW}
var state: STATE = STATE.IDLE
## Which climbing routine to do
var climb_index: int = 0
## The target y position to move towards.
var y_target: float = global_position.y

func _ready() -> void:
	$Timers/StateTimer.start(climb_pause_time)
	y_target = global_position.y
	super()

func _physics_process(delta: float) -> void:
	match state:
		STATE.IDLE:
			# Wait for timeout.
			pass
		STATE.CLIMB:
			global_position.y = move_toward(global_position.y,y_target,move_speed*delta)

			if global_position.y == y_target:
				state = STATE.IDLE
				$Timers/StateTimer.start()
				animator.play("Wait")
				_look_at_player()
				#var dist: float = get_nearest_player_by_x()
				#if abs(dist < 64):
				#	state = STATE.THROW
				#	$Timers/ThrowTimer.start()
				#else:
					
		STATE.THROW:
			pass

func _start_climb() -> void:
	y_target += climb_positions[climb_index]
	climb_index = wrapi(climb_index+1,0,climb_positions.size())
	state = STATE.CLIMB
	animator.play("Climb")

func _look_at_player() -> void:
	var look_dir: float = sign(get_nearest_player_by_x())
	scale.x = 0-sign(look_dir) if look_dir != 0 else 1

func throw_projectile():
	pass

func _on_state_timer_timeout() -> void:
	if state == STATE.IDLE:
		_start_climb()


func _on_throw_timer_timeout() -> void:
	pass # Replace with function body.
