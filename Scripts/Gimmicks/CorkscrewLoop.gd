@tool
extends Node2D


# player tracking arrays
var playerListL = []
var playerListR = []
var playerList = []

# length of the corkscrew
@export var length = 1

func _ready():
	# set initial positions for arrays
	$EnteranceR.position.x += $Corkscrew.texture.get_width()*(length-1)
	if !Engine.is_editor_hint():
		for i in length:
			if i > 0:
				var corkBG = $Corkscrew.duplicate()
				var corkFG = $CorkscrewFG.duplicate()
				add_child(corkBG)
				add_child(corkFG)
				corkBG.position.x += corkBG.texture.get_width()*i
				corkFG.position.x += corkFG.texture.get_width()*i

func _process(_delta):
	if Engine.is_editor_hint():
		$EnteranceR.position.x = $Corkscrew.texture.get_width()*(length-1)+($Corkscrew.texture.get_width()/2)
		queue_redraw()

func _physics_process(_delta):
	if !Engine.is_editor_hint():
		# Check for player encounters
		for i in playerListL: # left side
			if (i.global_position.x > $EnteranceL.global_position.x-8) and i.movement.x >= i.top/2 and round(i.movement.y) == 0:
				if (!playerList.has(i)):
					playerList.append(i)
		
		for i in playerListR: # right side
			if (i.global_position.x < $EnteranceR.global_position.x+8) and i.movement.x <= -i.top/2 and round(i.movement.y) == 0:
				if (!playerList.has(i)):
					playerList.append(i)
		
		# Set player sprites
		for i in playerList:
			if (i.currentState != i.STATES.CORKSCREW and i.currentState != i.STATES.JUMP):
				# Set state
				i.set_state(i.STATES.CORKSCREW)
				# Animation check
				if i.animator.current_animation != "roll":
					if (i.direction > 0):
						i.animator.play("corkScrew")
					else:
						i.animator.play("corkScrewOffset")
			
			# Set vertical movement to 0 so player doesn't fall off
			elif (i.currentState == i.STATES.CORKSCREW):
				i.movement.y = 0
			
			# Set the player position based on x position and the distance between the corkscrews origin
			# this uses a cosine function to create a wave pattern
			var yDistance = 32-((i.currentHitbox.NORMAL.y*2)-13)
			i.global_position.y = global_position.y+((cos(clamp((i.global_position.x-global_position.x)/(192*scale.x),-1,2*length)*PI)*yDistance)-2)*scale.y
			
			# Make player camera update as this change is applied after player movement
			i.cam_update()

			# Animation
			if i.animator.current_animation == "corkScrew" or i.animator.current_animation == "corkScrewOffset":
				var animSize = i.animator.current_animation_length
				i.animator.advance(-i.animator.current_animation_position+animSize-(global_position.x-i.global_position.x+(192*scale.x))/((192*scale.x)*2)*animSize)
			
			# Check to see if to remove player
			if (i.global_position.x < $EnteranceL.global_position.x-8 or i.global_position.x > $EnteranceR.global_position.x+8 or abs(i.movement.x) < i.top/2 or i.currentState == i.STATES.JUMP):
				if (playerList.has(i)):
					if i.currentState == i.STATES.CORKSCREW:
						if i.animator.current_animation != "roll":
							i.set_state(i.STATES.AIR)
						else:
							i.set_state(i.STATES.ROLL)
					else:
						# otherwise reset animation settings
						var animMem = i.animator.current_animation
						i.animator.play("RESET")
						i.animator.queue(animMem)
					playerList.erase(i)



# player checks
func _on_EnteranceL_body_entered(body):
	if !playerListL.has(body):
		playerListL.append(body)


func _on_EnteranceL_body_exited(body):
	if (playerListL.has(body)):
		playerListL.erase(body)

func _on_EnteranceR_body_entered(body):
	if !playerListR.has(body):
		playerListR.append(body)


func _on_EnteranceR_body_exited(body):
	if (playerListR.has(body)):
		playerListR.erase(body)

# draw self several times based on length
func _draw():
	if Engine.is_editor_hint():
		if length > 0:
			for i in length:
				if i > 0:
					var getTexture = $Corkscrew.texture
					draw_texture(getTexture,Vector2(getTexture.get_width()*i-getTexture.get_width()/2,-getTexture.get_height()/2))
