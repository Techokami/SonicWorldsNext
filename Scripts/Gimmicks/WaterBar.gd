extends Area2D

# Vertical Swinging Bar from Mushroom Hill Zone
# Author: Sharb (this is a modified version of the Vertical Bar by DimensionWarped)

# Sound to play when the bar is grabbed
@export var grabSound = preload("res://Audio/SFX/Player/Grab.wav")
# Sound to play when bar broken
@export var collapseSFX = preload("res://Audio/SFX/Gimmicks/Collapse.wav")

# falling sprite particle (repurposed from the falling block platform pieces)
var breakPart = preload("res://Entities/Misc/falling_block_plat.tscn")
# sprite (for reference for breaking parts)
@export_node_path("Sprite2D") var getSprite
# how many pieces should the sprite split into (vertically)
@export var spriteSplits = 8

# How many seconds before the bar breaks
@export var strength = 3.0
# Used for reseting the bar strength
@onready var startStrength = strength

var players = [] # Tracks the players that are active within the gimmick


# Called when the node enters the scene tree for the first time.
func _ready():
	$Grab.stream = grabSound

# check for players and if the jump button is pressed, release them from the poll
func _process(_delta):
	for i in players:
		if i.any_action_pressed():
			remove_player(i)
	

func _physics_process(delta):
	
	# Iterate through every player to see if they should be mounted to the bar
	for i in players:
		if !(check_grab(i)):
			continue
			
		# ignore if player is dead
		if i.currentState == i.STATES.DIE:
			break
		i.sprite.flip_h = (i.movement.x < 0)
		
		# Drop all the speed values to 0 to prevent issues.
		i.groundSpeed = 0
		i.movement.x = 0
		# this gimmick needs to be used in conjunction with the wind current,
		# vertical movement is handled by the current so we just slow it down here
		i.movement.y = i.movement.y*0.25
		i.cam_update()
	
	for i in players:
		if i.currentState == i.STATES.ANIMATION:
			i.global_position.x = get_parent().get_global_position().x
	# decrease strength if any players are holding
	if players.size() > 0:
		if strength > 0:
			strength -= delta
		else:
			# play sound globally (prevents sound overlap, aka loud sounds)
			Global.play_sound(collapseSFX)
			# directiont the players moving in
			var releaseDirection = 1
			# release players
			for i in players:
				# set release direction to the players direction
				releaseDirection = i.direction
				remove_player(i)
			# hide sprite visibility
			get_parent().visible = false
			# create sprite particles
			for i in spriteSplits:
				var part = breakPart.instantiate()
				part.texture = get_node(getSprite).texture
				part.centered = true
				var getSplitHeight = part.texture.get_height()/spriteSplits
				# set position and source sprite
				part.region_rect.position = Vector2(0,getSplitHeight*i)
				part.region_rect.size = Vector2(part.texture.get_width(),getSplitHeight)
				# add to scene
				get_parent().get_parent().add_child(part)
				# set to position
				part.global_position = global_position+part.region_rect.position+Vector2(0,(getSplitHeight/2.0)-(part.texture.get_height()/2.0))
				# set the velocity
				part.velocity = Vector2(releaseDirection*(220-abs(remap(i,0,spriteSplits,-100,80))),remap(i,0,spriteSplits,-100,50))
			queue_free() # delete
	# reset strenght
	else:
		strength = startStrength


func check_grab(body):
		
	# Skip if already on the vertical bar or player is jumping
	if (body.currentState == body.STATES.ANIMATION):
		return true
		
	return false
	
	
func _on_VerticalBarArea_body_entered(body):
	if body != get_parent(): #check that parent isn't going to be carried
		if !players.has(body):
			players.append(body)
			$Grab.play()
			# use offset vertical bar cling if the sprite is flipped
			body.set_state(body.STATES.ANIMATION, body.currentHitbox.HORIZONTAL)
			if body.sprite.flip_h:
				body.animator.play("clingVerticalBarOffset")
			else:
				body.animator.play("clingVerticalBar")

func _on_VerticalBarArea_body_exited(body):
	remove_player(body)
	
func remove_player(player):
	if players.has(player):
		# reset player animation
		player.animator.play("current")
		# Clean out the player from all player-linked arrays.
		players.erase(player)
