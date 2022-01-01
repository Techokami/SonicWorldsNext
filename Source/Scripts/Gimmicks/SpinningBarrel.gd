extends KinematicBody2D

var playerList = []
var playerOffset = [0]
var playerDistance = [0]


func _physics_process(delta):
	if playerOffset.size() < playerList.size():
		playerOffset.resize(playerList.size())
	if playerDistance.size() < playerList.size():
		playerDistance.resize(playerList.size())
	
	for i in playerList.size():
		var player = playerList[i]
		playerOffset[i] += delta*1.5
		player.global_position.x = global_position.x + cos(playerOffset[i]*PI)*playerDistance[i]*(24*global_scale.x)
		if (abs(playerDistance[i]) > 1):
			playerDistance[i] -= delta*sign(playerDistance[i])
		
		# set animation frame
		var getFrameOff = min(sign(playerDistance[i]),0)
		var frameCount = player.spriteFrames.get_frame_count("turnStand")
		player.sprite.frame = posmod((playerOffset[i]+getFrameOff)*frameCount/2,frameCount)
		

# Floor check
func physics_floor_override(body,caster):
	body.velocity = Vector2.DOWN
	body.sprite.play("turnStand");
	body.spriteFrames.set_animation_speed("turnStand",0);
	body.sprite.flip_h = true
	body.set_state(body.STATES.JUMPCANCEL);
	if (!playerList.has(body)):
		playerDistance[playerList.size()] = (body.global_position.x-global_position.x)/(24*global_scale.x)
		playerOffset[playerList.size()] = 0
		playerList.append(body)
	return true;

# player leaving check
func _on_PlayerCheck_body_exited(body):
	if (playerList.has(body)):
		playerList.erase(body)

