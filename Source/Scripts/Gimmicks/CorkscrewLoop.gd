extends Node2D

var playerListL = []
var playerListR = []

var playerList = []



func _physics_process(delta):
	# Check for player encounters
	for i in playerListL:
		if sign($EnteranceL.global_position.x-i.global_position.x) < sign($EnteranceL.global_position.x-i.global_position.x+(i.movement.x*delta)) && abs(i.movement.x) >= i.top/2:
			if (!playerList.has(i)):
				playerList.append(i)
	
	for i in playerListR:
		if sign($EnteranceR.global_position.x-i.global_position.x) > sign($EnteranceR.global_position.x-i.global_position.x+(i.movement.x*delta)) && abs(i.movement.x) >= i.top/2:
			if (!playerList.has(i)):
				playerList.append(i)
	
	for i in playerList:
		i.movement.y = 0
		if (i.currentState != i.STATES.CORKSCREW):
			i.set_state(i.STATES.CORKSCREW);
			#i.spriteFrames.set_animation_speed("corkScrew",0);
			#if i.sprite.animation != "roll":
			#	i.sprite.play("corkScrew");
		
		i.global_position.y = ((global_position.y+cos(clamp((i.global_position.x-global_position.x)/(192*scale.x),-1,1)*PI)*-32)-4)*scale.y
		# animation
#
#		if i.sprite.animation == "corkScrew":
#			#Forwards
#			if (!i.sprite.flip_h):
#				i.sprite.frame = i.spriteFrames.get_frame_count("corkScrew")-((global_position.x-i.global_position.x+192)/(192*2)*i.spriteFrames.get_frame_count("corkScrew"))
#			else:
#				i.sprite.flip_v = true
#				i.sprite.position.y = 8
#				i.sprite.frame = posmod((i.spriteFrames.get_frame_count("corkScrew")/2)-i.spriteFrames.get_frame_count("corkScrew")+((global_position.x-i.global_position.x+192)/(192*2)*i.spriteFrames.get_frame_count("corkScrew")),i.spriteFrames.get_frame_count("corkScrew"))
#
		if (i.global_position.x < $EnteranceL.global_position.x || i.global_position.x > $EnteranceR.global_position.x || abs(i.movement.x) < i.top/2):
			if (playerList.has(i)):
				playerList.erase(i)
				i.sprite.flip_v = false
				i.sprite.position.y = 0




func _on_EnteranceL_body_entered(body):
	if (!playerListL.has(body)):
		playerListL.append(body)


func _on_EnteranceL_body_exited(body):
	if (playerListL.has(body)):
		playerListL.erase(body)




func _on_EnteranceR_body_entered(body):
	if (!playerListR.has(body)):
		playerListR.append(body)


func _on_EnteranceR_body_exited(body):
	if (playerListR.has(body)):
		playerListR.erase(body)
