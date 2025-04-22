class_name ProcessTimer extends Node
## Process-based timer class.
##
## Mostly mimics what regular [Timer]s do, but with the following differences:[br]
##   • Doesn't implement [code]time_left[/code] and [code]wait_time[/code] properties,
##     as well as any setters/getters associated with them.[br]
##   • Fires on each frame (or physics frame, depending on what is specified
##     in [member process_callback]).[br]
##   • Passes an extra [code]delta[/code] argument in [signal timeout] signal to keep track
##     of time passed since the last [signal timeout] was emitted.

signal timeout(delta: float) ## Emitted on each frame (or physics frame).

enum TimerProcessCallback {
	TIMER_PROCESS_PHYSICS, ## Fire on each physics process frame (see [method Node._process]).
	TIMER_PROCESS_IDLE ## Fire on each process frame (see [method Node._physics_process]).
}

## Determines whether the timer fires on each frame or physics frame.
@export_custom(PROPERTY_HINT_ENUM, "Physics,Idle")
var process_callback: TimerProcessCallback = TimerProcessCallback.TIMER_PROCESS_IDLE:
	set = set_process_callback

@export var autostart: bool = false ## If [code]true[/code], the timer will start immediately when entering the scene tree.
@export var one_shot: bool = false ## If [code]true[/code], the timer will stop after firing once.

var paused: bool = false ## [code]true[/code] if the timer is paused.
var _running: bool = false

## Starts the timer.
func start() -> void:
	_running = true
	_update_process_callbacks()

## Stops the timer.
func stop() -> void:
	_running = false
	_update_process_callbacks()

## Returns [code]true[/code] if the timer is stopped or has not started.
func is_stopped() -> bool:
	return not _running

## Returns [code]true[/code] if the timer is set to start automatically after entering the scene tree.
func has_autostart() -> bool:
	return autostart

## Sets whether the timer will start automatically after entering the scene tree.
func set_autostart(value: bool) -> void:
	autostart = value

## Returns [code]true[/code] if the timer is set to stop after firing once.
func is_one_shot() -> bool:
	return one_shot

## Sets whether the timer will stop after firing once.
func set_one_shot(value: bool) -> void:
	one_shot = value

## Returns [code]true[/code] if the timer is paused.
func is_paused() -> bool:
	return paused

## Pauses/unpauses the timer.
func set_paused(value: bool) -> void:
	paused = value
	_update_process_callbacks()

## Returns [constant TIMER_PROCESS_IDLE] if the timer fires on each frame
## or [constant TIMER_PROCESS_PHYSICS] if it fires on each physics frame.
func get_process_callback() -> TimerProcessCallback:
	return process_callback

## Sets whether the timer fires on each frame or physics frame.
func set_process_callback(value: TimerProcessCallback) -> void:
	process_callback = value
	_update_process_callbacks()

func _update_process_callbacks() -> void:
	set_physics_process(_running and not paused and process_callback == TimerProcessCallback.TIMER_PROCESS_PHYSICS)
	set_process(_running and not paused and process_callback == TimerProcessCallback.TIMER_PROCESS_IDLE)

func _timer_tick(delta: float) -> void:
	timeout.emit(delta)
	if one_shot:
		stop()

func _process(delta: float) -> void:
	_timer_tick(delta)

func _physics_process(delta: float) -> void:
	_timer_tick(delta)

func _ready() -> void:
	_update_process_callbacks()
	if autostart:
		autostart = false
		start()
