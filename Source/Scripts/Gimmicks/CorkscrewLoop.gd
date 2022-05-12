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
		if (i.currentState != i.STATES.CORKSCREW && i.currentState != i.STATES.JUMP):
			i.set_state(i.STATES.CORKSCREW)
			if i.animator.current_animation != "roll":
				if (!i.sprite.flip_h):
					i.animator.play("corkScrew")
				else:
					i.animator.play("corkScrewOffset")
		elif (i.currentState == i.STATES.CORKSCREW):
			i.movement.y = 0
		
		i.global_position.y = ((global_position.y+cos(clamp((i.global_position.x-global_position.x)/(192*scale.x),-1,1)*PI)*-32)-4)*scale.y
		i.cam_update()
		# animation
		if i.animator.current_animation == "corkScrew" || i.animator.current_animation == "corkScrewOffset":
			var animSize = i.animator.current_animation_length
			i.animator.advance(-i.animator.current_animation_position+animSize-(global_position.x-i.global_position.x+192)/(192*2)*animSize)
				
		if (i.global_position.x < $EnteranceL.global_position.x || i.global_position.x > $EnteranceR.global_position.x || abs(i.movement.x) < i.top/2 || i.currentState == i.STATES.JUMP):
			if (playerList.has(i)):
				playerList.erase(i)
		i.ground = true




func _on_EnteranceL_body_entered(body):
	if (!playerListL.has(body) && body.get("ground")):
		playerListL.append(body)


func _on_EnteranceL_body_exited(body):
	if (playerListL.has(body)):
		playerListL.erase(body)




func _on_EnteranceR_body_entered(body):
	if (!playerListR.has(body) && body.get("ground")):
		playerListR.append(body)


func _on_EnteranceR_body_exited(body):
	if (playerListR.has(body)):
		playerListR.erase(body)
