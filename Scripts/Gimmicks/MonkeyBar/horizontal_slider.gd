## Horizontal Slider by DimensionWarped
## The horizontal slider is a simple script for making an object move left
## and right along a slider. You configure its speed, acceleration, and breaking
## force and then tell it you want it to move to a given position by calling its
## go_to_position function.
## 
## Positions are intended to be X positions only in its
## current form.
## 
## You can use this as a parent to control other objects. When you
## tell the object to go to position X, it will accelerate to speed and then
## apply the braking force only when needed to reach the destination.

extends Node2D

## Horizontal Slider's top speed in pixels per second
@export var top_speed = 240.0

## Horizontal Slider's forward acceleration in pixels per second squared
@export var forward_acceleration = 240.0

## Horizontal Slider's braking acceleration in pixels per second squared
@export var braking_acceleration = 360.0

## Where the slider is heading (x position relative to its parent)
var cur_target = position.x

## What the current speed of the slider is (x scale only)
var cur_velocity = 0.0

## Used to check if we're still accelerating
var last_velocity = 0.0

## Enum for slider state
## IDLE - the slider is at rest and at its current target
## MOVE_START - the slider has begun moving and is either accelerating or
##              maintaining speed
## MOVE_BRAKE - the slider has determined that it needs to apply brakes to
##              reach the slider when it comes to rest
enum STATE {IDLE, MOVE_START, MOVE_BRAKE}
var state = STATE.IDLE
var cur_cooldown = 0.0

## This signal will be emitted when the slider begins moving
signal movement_started

## This signal will be emitted when the slider accelerates to top speed
signal top_speed_reached

## This signal will be emitted when the slider begins braking
signal applied_brakes

## This signal will be emitted when the slider comes to a complete stop after
## braking
signal slider_stopped

## This signal will be emitted when the slider reaches its target
## The primary difference between this and sldier stopped is that if the target
## changes, the slider may have to stop at a place that isn't its target
signal target_reached

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	

func process_idle(delta) -> void:
	if cur_cooldown > 0:
		cur_cooldown -= delta
		return

	if cur_target != position.x:
		state = STATE.MOVE_START
		movement_started.emit()
	pass
	
func should_i_brake() -> bool:
	var target_relative_to_position = position.x - cur_target
	# Is the target to our left or our right?
	var direction_to_target = -sign(target_relative_to_position)
	
	# Uh... we are already past the target. We better brake as soon as we can.
	# In the case of zero, we are already stopped, so no need for brakes.
	if sign(cur_velocity) != direction_to_target and sign(cur_velocity) != 0:
		return true
	
	# How long it takes to brake from this velocity to hit 0 velocity
	var time_to_brake = abs(cur_velocity) / braking_acceleration
	
	# Distance to brake is 1/2 a*t^2
	var distance_to_brake = 0.5 * braking_acceleration * (time_to_brake * time_to_brake)
	
	if distance_to_brake >= abs(target_relative_to_position):
		return true
		
	return false
	
func process_move_common(delta: float) -> void:
	position.x += cur_velocity * delta

func process_move_start(delta: float) -> void:
	if should_i_brake():
		state = STATE.MOVE_BRAKE
		applied_brakes.emit()
		return
	
	process_move_common(delta)
	
	var position_relative_to_target = position.x - cur_target
	var direction_to_target = -sign(position_relative_to_target)
	
	cur_velocity += direction_to_target * forward_acceleration * delta

	# Clamp at top speed
	if cur_velocity * sign(cur_velocity) > top_speed:
		cur_velocity = sign(cur_velocity) * top_speed

	# If this is the first frame that we are at top speed for, emit the signal
	if cur_velocity != 0 and cur_velocity == sign(cur_velocity) * top_speed and last_velocity != cur_velocity:
		top_speed_reached.emit()
	
	last_velocity = cur_velocity

func process_move_brake(delta: float) -> void:
	process_move_common(delta)
	var abs_check = false

	var velocity_sign = sign(cur_velocity)
	cur_velocity -= delta * velocity_sign * braking_acceleration
	
	# close enough target lock
	abs_check = abs(position.x - cur_target) < 2.0
	if abs_check or velocity_sign * cur_velocity <= 0.0:
		if abs_check:
			target_reached.emit()
			position.x = cur_target
		cur_velocity = 0
		state = STATE.IDLE
		slider_stopped.emit()

	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	match state:
		STATE.IDLE:
			return(process_idle(delta))
		STATE.MOVE_START:
			return(process_move_start(delta))
		STATE.MOVE_BRAKE:
			return(process_move_brake(delta))
	

## Sets the target X position of the slider
func send_to_target(target_x_pos : int):
	cur_target = target_x_pos
	pass
