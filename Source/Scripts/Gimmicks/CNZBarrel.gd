extends Node2D

# XXX Combine all players arrays into one to improve efficiency of attach/detach
# contains currently attached players.
var players = []
# contains the phase (their movement around the barrel) - accumulated with relation to
# spinning_period during the physics_process.
var players_phase = []
# Depending on where you initially connect to the gimmick, your radius is set based
# on how far you were from the center of the barrel.
var players_radius = []
# array of players z levels upon interacting with the gimmick. The Z level is offset
# by the player's phase while on the gimmick, this is so we can restore it when they
# detach
var players_z_level = []

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
export var trampolineMode = false
# Play with this to determine the maximum distance the barrel can travel. It's going to take trial and error, sorry.
export var maxVel = 480.0

# Don't mess with the spring constants and/or decay values unless you're preparred to spend a long time tinkering.
# springConstantLoaded determines the force at which the spring bounces back when the energy in the spring is at its maximum.
export var springConstantLoaded = 2.0
# springConstantUnloaded determines the force at which the spring bounces back when the energy in the spring is at 0
export var springConstantUnloaded = 5.0
# decayLoaded determines how quickly the spring loses energy when the energy in the spring is at its maximum.
export var decayLoaded = 0.3
# decayUnloaded determines how quickly the spring loses energy when the energy in the spring is at 0
export var decayUnloaded = 1.0
# influence determines how much energy the player's directional influence imparts
export var influence = 1.0
# impartFactor determines how much the motion of the platform impacts the player when they jump off
export var impartFactor = 0.8

# Calcuated based on max velocity, load energy is the amount of energy at which the Loaded constants have full influence
var loadEnergy

# Were one or more players holding up on the last pass through process
var upHeld = false
# Were one or more players holding down on the last pass through process
var downHeld = false
# origin point of the platform, used for spring calculations... should probably always be 0
var _origin = 0
# y velocity of the platform, moves the platform, determines current energy in the platform when combined with difference between current position and origin
var _yVel = 0
# where the platform is in relation to its origin as a float value. Maybe unnecessary? Either way I'm using it.
var _realY = 0.0
# The physical parts of the body that move separate from the main node
onready var body = $CNZBarrelActiveBody

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	loadEnergy = 0.25 * maxVel * maxVel
	
func impart_force(velocityChange):
	_yVel += velocityChange
	_yVel = clamp(_yVel, -maxVel, maxVel)
	
func attach_player(player):
	if players.has(player):
		return

	player.set_state(player.STATES.ANIMATION)	
	players.append(player)
	players_z_level.append(player.get_z_index())

	var player_radius = player.global_position.x - global_position.x
	if (player_radius < 0):
		players_phase.append(PI)
		players_radius.append(min(max_radius, abs(player_radius)))
		player.animator.play("yRotation")
		player.animator.seek(0.5 * spinning_period + animation_offset)
	else:
		players_phase.append(0)
		players_radius.append(min(max_radius, player_radius))
		player.animator.play("yRotation")
		player.animator.seek(animation_offset)
		
	if trampolineMode:
		# Believe it or not, it really is this simple.
		impart_force(80.0)

	player.direction = 1
	player.sprite.flip_h = false

	# Prevents player from clipping on walls while they are on the fringes of the gimmick
	player.translate = true

	pass
func detach_player(player, index):
	
	players.remove(index)
	players_phase.remove(index)
	players_radius.remove(index)
	player.set_z_index(players_z_level[index])
	players_z_level.remove(index)
	
	# Clamp position on exit to prevent zips on exit -- probably shouldn't use magic numbers.
	player.global_position.x = clamp(player.global_position.x, global_position.x - 22, global_position.x + 22)
	
	if player.currentState != player.STATES.DIE:
		player.translate = false
		
func _process(delta):
	upHeld = false
	downHeld = false
	
	# Determine inputs, once it's available change player animations
	# Note that we only care if one player is holding a direction even if they
	# are fighting eachother and only the direction of current travel matters.
	for player in players:
		if player.inputs[player.INPUTS.YINPUT] < 0:
			upHeld = true
			# XXX Set Up Current Animation once we have look up yRotation
		elif player.inputs[player.INPUTS.YINPUT] > 0:
			downHeld = true
			# XXX Set Up Current Animation once we have look down yRotation
	
	for player in players:
		var index = players.find(player)
		
		# Ok, this is clever.
		# If the player is closer to the center, the influence of their phase is diminished.
		player.set_z_index(get_z_index() + 2 * players_radius[index] * -sin(players_phase[index]))
			
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
			player.update()
			
			continue
			
		if player.currentState != player.STATES.ANIMATION:
			detach_player(player, index)

# Called every frame. 'delta' is the elapsed time since the previous frame.
var skipFrames = 0

func physics_process_trampoline_mode(delta, upHeld, downHeld):
	var energy = 0.25 * (_yVel * _yVel) + _realY * _realY
	var pivot = 0
	var accelerationFactor
	var loadFactor
	
	# Once we are at the loadEnergy level, we are fully loaded
	loadFactor = min(energy / loadEnergy, 1.0)
	
	var springConstant = springConstantLoaded * loadFactor + springConstantUnloaded * (1.0 - loadFactor)
	var decay = decayLoaded * loadFactor + decayUnloaded * (1.0 - loadFactor)
	
	accelerationFactor = (pivot - _realY) * springConstant
		
	var influenced = false
	
	if _realY > 0 and _yVel < 0 and upHeld:
		_yVel = clamp(_yVel - (180.0 * delta), -maxVel, maxVel)
		influenced = true
		pass
	elif _realY < 0 and _yVel > 0 and downHeld:
		_yVel = clamp(_yVel * (1 + (influence * delta)), -maxVel, maxVel)
		_yVel = clamp(_yVel + (180.0 * delta), -maxVel, maxVel)
		influenced = true
		pass

	_yVel += accelerationFactor * delta
	_realY += _yVel * delta
	
	if !influenced:
		_yVel = _yVel * (1 - (decay * delta))
		pass

	body.position.y = floor(_realY)

	pass

func _physics_process(delta):
	if trampolineMode:
		physics_process_trampoline_mode(delta, upHeld, downHeld)
	for player in players:
		var index = players.find(player)
		player.direction = 1
		players_phase[index] += (delta / spinning_period) * 2.0 * PI
		player.global_position.x = floor(body.global_position.x + players_radius[index] * cos(players_phase[index]))
		player.global_position.y = floor(body.global_position.y - player.currentHitbox.NORMAL.y - 2)
		player.movement.x = 0
		player.movement.y = 0
		player.cam_update()
