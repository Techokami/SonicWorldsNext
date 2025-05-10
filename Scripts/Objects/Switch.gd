extends StaticBody2D

# animator is optional
## Optionally choose an AnimationPlayer for this switch to control
@export_node_path("AnimationPlayer")var animator

## When using animator with this switch, use animationName to automatically set
## the animation of animator to the animation of this name
@export var animationName = ""

## If false, the switch will automatically release when whatever is holding it down
## gets off the switch, at which point the 'released' signals will be sent.
@export var reactivate = true

var active = false
var colCheck = false
var animatorNode = null

## Emitted when the switch is pressed - includes the player character
## responsible for pushing the switch as an argument
signal pressed_with_body(body)

## Emitted when the switch is pressed - no args
signal pressed

## Emitted when the switch is released - no args
signal released


func _process(_delta):
	if animator != null:
		animatorNode = get_node_or_null(animator)
	if active:
		# set frame to pressed frame
		$Sprite2D.frame = 1
	else:
		# set frame to unpressed frame
		$Sprite2D.frame = 0
	
func _physics_process(_delta):
	# active gets set every physics process frame so we use collision check as a buffer, when col check isn't set then we deactivate
	# note: only turn off if reactivate is off
	if colCheck:
		colCheck = false
	elif reactivate:
		deactivate()

# Collision check
func physics_collision(body, hitVector):
	if hitVector.is_equal_approx((Vector2.DOWN*scale.sign()).rotated(deg_to_rad(snapped(rotation_degrees,90)))):
		# set colCheck to true to prevent being deactivated next frame
		colCheck = true
		
		if !active:
			# activate and emit signal for being pressed so other nodes can react
			active = true
			$Switch.play()
			pressed_with_body.emit(body)
			pressed.emit()
			# play animation if a node is hooked up
			if (animatorNode != null):
				animatorNode.play(animationName)
		return true

## This can depress a switch using a remote signal. Only really useful if
## Reactivate is false.
func deactivate():
	active = false
	released.emit()
