# Fires with every `_process()` call (or `_physics_process()`,
# depending on what you choose in `process_callback`)
extends Node

signal timeout(delta:float)

enum TimerProcessCallback { TIMER_PROCESS_PHYSICS, TIMER_PROCESS_IDLE }
@export_enum("Physics", "Idle") var process_callback = TimerProcessCallback.TIMER_PROCESS_IDLE as int:
	set(value):
		process_callback = value
		_update_process_callbacks()

@export var autostart:bool = false
@export var one_shot:bool = false

var running:bool = false
var paused:bool = false

func _update_process_callbacks() -> void:
	set_physics_process(running and not paused and process_callback == TimerProcessCallback.TIMER_PROCESS_PHYSICS as int)
	set_process(running and not paused and process_callback == TimerProcessCallback.TIMER_PROCESS_IDLE as int)

func set_autostart(value:bool) -> void:
	autostart = value

func has_autostart() -> bool:
	return autostart

func start() -> void:
	running = true
	_update_process_callbacks()

func stop() -> void:
	running = false
	_update_process_callbacks()

func set_paused(value:bool) -> void:
	paused = value
	_update_process_callbacks()

func _timer_tick(delta:float) -> void:
	timeout.emit(delta)
	if one_shot:
		stop()

func _process(delta:float) -> void:
	_timer_tick(delta)

func _physics_process(delta:float) -> void:
	_timer_tick(delta)

func _ready() -> void:
	_update_process_callbacks()
	if autostart:
		start()
