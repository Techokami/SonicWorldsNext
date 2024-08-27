extends Node2D

# Array of Arrays for each player interacting with the gimmick...
# Please don't access/mutate this array directly, use the relevant functions
# or add new ones where needed.
#
# [n][0] - player's object id
#
# [n][1] - player's phase - This is their current angle spinning around the top of the barrel
#
# [n][2] - player's radius - The radius of their spinning - if they jump on the barrel closer to the
#          edge, their radius will be larger. If they jump on the barrel dead center, their radius
#          will be zero.
#
# [n][3] - player's z level - the z level index that the player originally entered the gimmick on.
#          Needs to be restored after disconnecting from the gimmick. While on the gimmick, the
#          player's z level index will be shifted every frame according to their radius and phase.
#
# XXX - consider a statically sized array that knows the count of players at the start (possibly stored in globals?)
# for optimal efficiency.
var players = []

# Use to find the index of the player using the player's object ID
# Return values are the Same as Array.find(obj), but this function takes into
# account the specific nesting of the array and treats players[n][0] as the key
func find_player(player):
	for i in players.size():
		if players[i][0] == player:
			return i
	return -1

# Use to get the player at the index of the array.
# Returns the player if the index isn't out of bounds, otherwise returns null.
func get_player(index):
	if players.size() >= index + 1:
		return players[index][0]
	return null
	
#func append_player(player, phase, radius, z_level):
#	players.append([player, phase, radius, z_level])
	
func get_player_phase(index):
	return players[index][1]

func set_player_phase(index, value):
	players[index][1] = value
	
func get_player_radius(index):
	return players[index][2]
	
func get_player_z_level(index):
	return players[index][3]

# We want to bring the player back in a little if they are on the extreme overhang of the radius
var max_radius = 30

# The animation offset makes it so that you aren't exactly synchronized with the
# rotation around the barrel. The default value advances the animation by 0.03
# seconds to try to closely synchronize the camera facing frame with where it would
# pop up if you were on the actual barrel from CNZ
var animation_offset = -0.02

# how many seconds (should be expressed as frames / 60.0) it takes to go around the platform
# Note that this is the same as the number of frames in the yRotation animation and changing
# this will mean throwing off a bunch of stuff.
var spinning_period = 128.0 / 60.0

# Enable the trampoline mode. Needs to be combined with a maxVel to limit the maximum distance traveled.
# MaxVel affects the maximum velocity that can be held at any time which effectively limits the maximum
# distance the gimmick can travel. The closer the current velocity is to the maxVel (absolute), the less impact
# jumping on will have on the velocity.
@export var trampolineMode = false
# Play with this to determine the maximum distance the barrel can travel. It's going to take trial and error, sorry.
@export var maxVel = 480.0

# Don't mess with the spring constants and/or decay values unless you're preparred to spend a long time tinkering.
# springConstantLoaded determines the force at which the spring bounces back when the energy in the spring is at its maximum.
@export var springConstantLoaded = 2.0
# springConstantUnloaded determines the force at which the spring bounces back when the energy in the spring is at 0
@export var springConstantUnloaded = 5.0
# decayLoaded determines how quickly the spring loses energy when the energy in the spring is at its maximum.
@export var decayLoaded = 0.3
# decayUnloaded determines how quickly the spring loses energy when the energy in the spring is at 0
@export var decayUnloaded = 1.0
# influence determines how much energy the player's directional influence imparts
@export var influence = 1.0
# impartFactor determines how much the motion of the platform impacts the player when they jump off
@export var impartFactor = 0.8

# Calcuated based on max velocity, load energy is the amount of energy at which the Loaded constants have full influence
var loadEnergy

# Were one or more players holding up on the last pass through process
var upHeld = false
# Were one or more players holding down on the last pass through process
var downHeld = false
# origin point of the platform, used for spring calculations... should probably always be 0
#var _origin = 0 #currently unused
# y velocity of the platform, moves the platform, determines current energy in the platform when combined with difference between current position and origin
var _yVel = 0
# where the platform is in relation to its origin as a float value. Maybe unnecessary? Either way I'm using it.
var _realY = 0.0
# The physical parts of the body that move separate from the main node
@onready var body = $CNZBarrelActiveBody

# Called when the node enters the scene tree for the first time.
func _ready():
	loadEnergy = 0.25 * maxVel * maxVel

func impart_force(velocityChange):
	_yVel += velocityChange
	_yVel = clamp(_yVel, -maxVel, maxVel)

func attach_player(player):
	# If the player is already in the array, reject the attachment attempt
	if find_player(player) >= 0:
		return

	player.set_state(player.STATES.ANIMATION)	
	var player_z_level = player.get_z_index()
	var player_radius = clamp(player.global_position.x - global_position.x, -max_radius, max_radius)
	var player_phase = 0
	player.animator.play("yRotation")
	if (player_radius < 0):
		player_radius = player_radius * -1.0
		player_phase = PI
		player.animator.advance(animation_offset)

	players.append([player, player_phase, player_radius, player_z_level])

	if trampolineMode:
		# Believe it or not, it really is this simple.
		impart_force(80.0)

	player.direction = 1
	player.sprite.flip_h = false

	# Prevents player from clipping on walls while they are on the fringes of the gimmick
	player.translate = true

func detach_player(player, index):
	player.set_z_index(get_player_z_level(index))
	players.remove_at(index)
	
	if player.currentState == player.STATES.DIE:
		player.animator.play("die")

	# Clamp position on exit to prevent zips on exit -- probably shouldn't use magic numbers.
	player.global_position.x = clamp(player.global_position.x, global_position.x - 22, global_position.x + 22)

	if player.currentState != player.STATES.DIE:
		player.translate = false
		
func set_anim(player, lookUp, lookDown):
	var curAnim = player.animator.get_assigned_animation()
	var targetAnim
	
	if lookUp and !lookDown:
		targetAnim = "yRotationLookUp"
	elif lookDown and !lookUp:
		targetAnim = "yRotationLookDown"
	else:
		targetAnim = "yRotation"
		
	if targetAnim != curAnim:
		var seekTime = player.animator.get_current_animation_position()
		player.animator.play(targetAnim)
		player.animator.advance(seekTime)
		if targetAnim == "yRotationLookDown":
			#player.set_hitbox(player.currentHitbox.CROUCH, true)
			player.get_node("HitBox").shape.size = player.currentHitbox.CROUCH
			player.get_node("HitBox").position = player.hitBoxOffset.crouch
		else:
			#player.set_hitbox(player.currentHitbox.NORMAL, true)	
			player.get_node("HitBox").position = player.hitBoxOffset.normal
			player.get_node("HitBox").shape.size = player.currentHitbox.NORMAL

func _process(delta):
	upHeld = false
	downHeld = false

	# We loop backwards so that if we detach a player, they won't affect the index of the next player	
	for index in range(players.size() - 1, -1, -1):
		# Determine inputs, once it's available change player animations
		# Note that we only care if one player is holding a direction even if they
		# are fighting eachother and only the direction of current travel matters.
		var player = get_player(index)
		var playerHeldUp = false
		var playerHeldDown = false
		if player.inputs[player.INPUTS.YINPUT] < 0:
			upHeld = true
			playerHeldUp = true
		elif player.inputs[player.INPUTS.YINPUT] > 0:
			downHeld = true
			playerHeldDown = true
		
		set_anim(player, playerHeldUp, playerHeldDown)

		# If the player is closer to the center, the influence of their phase is diminished.
		player.set_z_index(get_z_index() + 2 * get_player_radius(index) * -sin(get_player_phase(index)))

		if player.any_action_pressed():
			detach_player(player, index)
			# Whoa, jump!
			player.action_jump("roll", true, false)
			
			# Jump should never go downwards
			#player.movement.y = min(player.movement.y - _yVel * impartFactor, -player.jmp)
			player.movement.y = min(player.movement.y + _yVel * impartFactor, 0)
			# pop the player up a bit to make sure they don't make immediate contact again.
			if _yVel > 0:
				player.position.y -= _yVel * delta + 10
			player.queue_redraw()
			continue
			
		if player.currentState != player.STATES.ANIMATION:
			detach_player(player, index)

# Called every frame. 'delta' is the elapsed time since the previous frame.
var skipFrames = 0

# Invoked if this gimmick operates as a trampoline.
func physics_process_trampoline_mode(delta, isUpHeld, isDownHeld):
	# Energy is the velocity energy plus the spring potential energy
	var energy = 0.25 * (_yVel * _yVel) + _realY * _realY
	var pivot = 0
	var accelerationFactor
	# in a zero energy system, the unloaded values are used
	# in a max energy system, the loaded values are used
	# anywhere in the middle, we use the weighted average
	var loadFactor = min(energy / loadEnergy, 1.0)
	var springConstant = springConstantLoaded * loadFactor + springConstantUnloaded * (1.0 - loadFactor)
	var decay = decayLoaded * loadFactor + decayUnloaded * (1.0 - loadFactor)

	# The further away from the pivot we are, the stronger the acceleration from the spring force
	accelerationFactor = (pivot - _realY) * springConstant

	# We don't apply decay if player influence was applied
	var influenced = false

	# The players only have influence while acceleration and velocity are working together
	# Also, holding against the direction of travel has no effect
	if _realY > 0 and _yVel < 0 and isUpHeld:
		_yVel = clamp(_yVel - (180.0 * delta), -maxVel, maxVel)
		influenced = true
	elif _realY < 0 and _yVel > 0 and isDownHeld:
		_yVel = clamp(_yVel * (1 + (influence * delta)), -maxVel, maxVel)
		_yVel = clamp(_yVel + (180.0 * delta), -maxVel, maxVel)
		influenced = true

	_yVel += accelerationFactor * delta
	_realY += _yVel * delta

	if !influenced:
		_yVel = _yVel * (1 - (decay * delta))

	# We move the body rather than the node. The body has all the physical components of the gimmick,
	body.position.y = floor(_realY)

func _physics_process(delta):
	if trampolineMode:
		physics_process_trampoline_mode(delta, upHeld, downHeld)

	for index in range(players.size()):
		var player = get_player(index)
		player.direction = 1
		set_player_phase(index, get_player_phase(index) + (delta / spinning_period) * 2.0 * PI)
		player.global_position.x = floor(body.global_position.x + get_player_radius(index) * cos(get_player_phase(index)))
		player.global_position.y = floor(body.global_position.y - player.currentHitbox.NORMAL.y / 2.0 - 1)
		if player.currentState != player.STATES.DIE:
			player.movement.x = 0
			player.movement.y = 0
		# XXX need to figure out why player 2 is mispositioned while this gimmick is moving quickly
		player.cam_update()
