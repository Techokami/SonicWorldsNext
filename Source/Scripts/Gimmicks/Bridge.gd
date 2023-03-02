@tool
extends Node2D

@export var length = 12
@export var smoothDrop = true #Turn to false to match sonic 1 bridges
@export (Texture2D)var texture = null
var dropIndex = 1
var maxDepression = 0

var player = []
var bridges = []
var buffer = 0

func _ready():
	if !Engine.is_editor_hint():
		# texture overwrite
		if (texture != null):
			$log.texture = texture
		$log.rotation -= rotation
		
		# Set mask positions
		$Bridge/mask.position += Vector2.RIGHT*length*8
		$Bridge/mask.scale.x = (length)
		$PlayerCheck/mask.position += Vector2.RIGHT*length*8
		$PlayerCheck/mask.scale.x = (length)
		
		# duplicate log sprites until it matches the length
		for _i in range(length-1):
			var newLog = $log.duplicate()
			add_child(newLog)
			bridges.append(newLog)
			$log.position.x += 16
		bridges.append($log)

func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()

func _physics_process(delta):
	if !Engine.is_editor_hint():
		
		var playerTouch = false
		
		for i in player:
			if i.movement.y >= 0:
				playerTouch = true
		
		if (playerTouch):
			# set buffer for colissions
			buffer = 1
			var averagePlayerOffset = 0
			for i in player:
				if i.movement.y >= 0:
					# check if average offset is set, if not then assign it to the first player
					if averagePlayerOffset == 0:
						averagePlayerOffset = i.global_position.x
					# get closest to center
					elif abs(averagePlayerOffset-(global_position.x+(length/2*16))) > abs(i.global_position.x-(global_position.x+(length/2*16))):
						averagePlayerOffset = lerp(averagePlayerOffset,i.global_position.x,0.5)
			
			$Bridge.position.y = max(floor(length/2)*2-snapped(abs(global_position.x+(length*8)-averagePlayerOffset)/8,2-int(smoothDrop)),0)
			dropIndex = max(1,floor((averagePlayerOffset-global_position.x)/16)+1)
			if (dropIndex <= length/2):
				maxDepression = dropIndex*2 #Working from the left
			else:
				maxDepression = ((length-dropIndex)+1)*2 #Working from the right
		# check buffer (gives 1 frame to check for collisions, crouching usually breaks this)
		elif buffer > 0:
			buffer -= 1
		else:
			# Reset if no player found
			$Bridge.position.y = 0
			dropIndex = 1
			maxDepression = 0
		
		$PlayerCheck.scale.y = (maxDepression/8)+1
			
		# Loop through all segments to find their y position
		for i in range(bridges.size()):
			# Get difference in position of this log to current log
			var difference = abs((i+1)-dropIndex)
			
			# Get distance from current log to the closest side
			var logDistance = 0
			if (i < dropIndex):
				logDistance = 1-(difference/dropIndex) # Working from the left
			else:
				logDistance = 1-(difference/((length-dropIndex)+1)) # Working from the right
			
			bridges[i].position.y = lerp(bridges[i].position.y,floor(maxDepression * sin(90 * deg_to_rad(logDistance))),delta*10)
		


# add players to array when entering or exiting area
func _on_PlayerCheck_body_entered(body):
	player.append(body)

func _on_PlayerCheck_body_exited(body):
	if (player.has(body)):
		player.erase(body)

# draw logs
func _draw():
	if Engine.is_editor_hint():
		for i in length:
			if i > 0:
				draw_texture($log.texture,Vector2(($log.texture.get_width()*i)-$log.texture.get_width()/2,-$log.texture.get_height()/2))
