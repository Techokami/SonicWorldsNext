extends KinematicBody2D

var playerList = []
var playerOffset = [0]
var playerDistance = [0]
var playerContactY = [0]

@export var bouncer = false
var selfVelocity = 0
@onready var startOff = position.y

#func _ready():
#	set_sync_to_physics(!bouncer)


func _physics_process(delta):
	var shift = Vector2(0,selfVelocity*delta)
	if (bouncer):
		translate(shift)
		
		if (round(snapped(position.y,4)) != round(snapped(startOff,4)) || abs(selfVelocity) > 100):
			if (sign(startOff-position.y) == sign(selfVelocity)):
				selfVelocity += 600*delta*sign(startOff-position.y)
			else:
				selfVelocity += 1200*delta*sign(startOff-position.y)
		else:
			position.y = startOff
			selfVelocity = 0
		
#		if (abs(selfVelocity) < 100 && abs(startOff-position.y) < 8):
#			selfVelocity = lerp(selfVelocity,0,delta*200)
			
	if playerOffset.size() < playerList.size():
		playerOffset.resize(playerList.size())
	if playerDistance.size() < playerList.size():
		playerDistance.resize(playerList.size())
	if playerContactY.size() < playerList.size():
		playerContactY.resize(playerList.size())
	
	for i in playerList.size():
		var player = playerList[i]
		playerOffset[i] += delta*1
		if (bouncer):
			player.global_position.y = global_position.y + playerContactY[i]
			selfVelocity += player.inputs[player.INPUTS.YINPUT]*delta*500
			
		player.global_position.x = global_position.x + cos(playerOffset[i]*PI)*playerDistance[i]*(24*global_scale.x)
		if (abs(playerDistance[i]) > 1):
			playerDistance[i] -= delta*sign(playerDistance[i])
		
		# set animation frame
		var getFrameOff = min(sign(playerDistance[i]),0)
		var frameCount = player.spriteFrames.get_frame_count("turnStand")
		player.sprite.frame = posmod((playerOffset[i]+getFrameOff)*frameCount/2,frameCount)
		



# Floor check
func physics_floor_override(body,caster):
	if (bouncer):
		if (!playerList.has(body)):
			selfVelocity = body.velocity.y
		#else:
		#	body.velocity.y = selfVelocity
	#else:
	body.velocity = Vector2.DOWN
	body.sprite.play("turnStand");
	body.spriteFrames.set_animation_speed("turnStand",0);
	body.sprite.flip_h = true
	body.set_state(body.STATES.JUMPCANCEL);
	if (!playerList.has(body)):
		playerDistance[playerList.size()] = (body.global_position.x-global_position.x)/(24*global_scale.x)
		playerOffset[playerList.size()] = 0
		playerContactY[playerList.size()] = body.global_position.y-global_position.y+1
		playerList.append(body)
	return true;

# player leaving check
func _on_PlayerCheck_body_exited(body):
	if (playerList.has(body)):
		playerList.erase(body)

