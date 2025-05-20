@tool
extends Area2D

## List of players currently riding the current
var players = []

## Power at which fan current propels the players riding
@export var speed = 90.0 # default power

## If enabled, the fan is on. Otherwise the fan needs to be turned on/off via signals.
@export var is_active: bool = true

## If disabled, the fan blows as long as it is active regardless of whether or not a player
## is riding.
## If enabled, the fan only blows when the player is overlapping the fan's collision area.
@export var touch_active: bool = false

## Whether or not the fan should play $FanSound when the fan starts blowing. TODO: Perhaps this
## would be better controlled by the presence of a "$FanSound" node.
@export var play_sound: bool = true

var get_frame = 0.0
var animation_speed = 0.0

func _ready():
	scale.x = max(1,scale.x)
	$fan.global_scale = Vector2(1,1)
	if $fan.texture != null:
		$fan.region_rect.size.x = $fan.texture.get_width()*round(scale.x)

func _process(delta):
	if Engine.is_editor_hint():
		scale.x = max(1,scale.x)
		$fan.global_scale = Vector2(1,1)
		if $fan.texture != null:
			$fan.region_rect.size.x = $fan.texture.get_width()*round(scale.x)
		# No need to cotinue running the rest if we are in hint mode
		return

	# animate
	var go_speed = 0.0
	if is_active:
		if !touch_active or players.size() > 0:
			go_speed = 30.0
			# play fan sound
			if play_sound and !$FanSound.playing:
				$FanSound.play()
		# end sound if playing
		elif $FanSound.playing:
			$FanSound.stop()
	# back up end sound
	elif $FanSound.playing:
		$FanSound.stop()
	
	animation_speed = lerp(animation_speed,go_speed,delta*1.5)
	$fan.frame = get_frame
	get_frame = wrapf(get_frame+delta*animation_speed,0,$fan.hframes*$fan.vframes)


func _physics_process(delta):
	# Do editor hints even run _physics_process?
	if Engine.is_editor_hint():
		return

	# if any players are found in the array, if they're on the ground make them roll
	for i: PlayerChar in players:
		var animator = i.get_avatar().get_animator()
		# determine the direction of the arrow based on scale and rotation
		# better method needs to be done
		# DW's note: commented out for now because this variable wasn't used and it was
		# causing a warning. Perhaps intended for multi-directional fans being added later?
		#var getDir = Vector2.UP.rotated(global_rotation)
			
		# disconect floor
		if i.is_on_ground():
			i.disconnect_from_floor()
			
		# set movement
		# get distance for the y axis
		var y_distance = (global_position.y-(16*scale.y)+cos(Global.levelTime*4)*4)
		
		# make sure player is in range
		if abs(y_distance-i.global_position.y) <= abs(y_distance-global_position.y):
			# move toward the top of the mask
			i.movement.y = lerp(i.movement.y, sign(y_distance-i.global_position.y)*speed-i.get_physics().gravity, delta*30)
		
		# force air state
		var setPlayerAnimation = "corkScrew"
		# water animation
		if i.water:
			setPlayerAnimation = "current"
			
		if (i.get_state() != PlayerChar.STATES.GIMMICK or
		        animator.get_current_animation() != setPlayerAnimation):
			i.set_state(PlayerChar.STATES.AIR)
			animator.play(setPlayerAnimation)

func _on_body_entered(body):
	if !players.has(body):
		players.append(body)

func _on_body_exited(body):
	if players.has(body):
		body.set_state(PlayerChar.STATES.NORMAL)
		players.erase(body)

func activate():
	is_active = true

func deactivate():
	is_active = false

func activate_touch_active():
	touch_active = true

func deactivate_touch_active():
	touch_active = false

# generate bubbles
func _on_bubble_timer_timeout():
	if is_active and (!touch_active or players.size() > 0):
		var pos: Vector2 = global_position+Vector2((16.0*abs(scale.x)-4.0)*randf_range(-1.0,1.0),-8.0*sign(scale.y))
		var impulse: Vector2 = Vector2(0.0,-speed*0.5)
		var max_distance: float = (global_position.y-(16*scale.y)+cos(Global.levelTime*4)*4)
		Bubble.create_small_or_medium_bubble(get_parent(),pos,impulse,max_distance)
