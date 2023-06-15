@tool
extends Area2D

var players = []
@export var speed = 90.0 # default power
@export var isActive = true
@export var touchActive = false
@export var playSound = true

var getFrame = 0.0
var animSpeed = 0.0


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
	# animate
	var goSpeed = 0.0
	if isActive:
		if !touchActive || players.size() > 0:
			goSpeed = 30.0
			# play fan sound
			if playSound && !Engine.is_editor_hint():
				if !$FanSound.playing:
					$FanSound.play()
		# end sound if playing
		elif $FanSound.playing:
				$FanSound.stop()
	# back up end sound
	elif $FanSound.playing:
			$FanSound.stop()
	
	animSpeed = lerp(animSpeed,goSpeed,delta*1.5)
	$fan.frame = getFrame
	getFrame = wrapf(getFrame+delta*animSpeed,0,$fan.hframes*$fan.vframes)



func _physics_process(delta):
	if !Engine.is_editor_hint():
		# if any players are found in the array, if they're on the ground make them roll
		if players.size() > 0:
			for i in players:
				# determine the direction of the arrow based on scale and rotation
				# better method needs to be done
				var getDir = Vector2.UP.rotated(global_rotation)
				
				# disconect floor
				if i.ground:
					i.disconect_from_floor()
				
				# set movement
				# move toward the top of the mask
				i.movement.y = lerp(i.movement.y, sign((global_position.y-(16*scale.y)+cos(Global.levelTime*4)*4)-i.global_position.y)*speed-i.grv, delta*30)
				
				# force air state
				var setPlayerAnimation = "corkScrew"
				# water animation
				if i.water:
					setPlayerAnimation = "current"
				
				if i.currentState != i.STATES.ANIMATION || i.animator.current_animation != setPlayerAnimation:
					i.set_state(i.STATES.AIR)
					i.animator.play(setPlayerAnimation)



func _on_body_entered(body):
	if !players.has(body):
		players.append(body)

func _on_body_exited(body):
	if players.has(body):
		body.set_state(body.STATES.NORMAL)
		players.erase(body)

func activate():
	isActive = true

func deactivate():
	isActive = false

func activate_touch_active():
	touchActive = true

func deactivate_touch_active():
	touchActive = false
