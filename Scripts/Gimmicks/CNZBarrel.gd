extends ConnectableGimmick

## We want to bring the player back in a little if they are on the extreme overhang of the radius.
const MAX_RADIUS: float = 30.0

## The animation offset makes it so that you aren't exactly synchronized
## with the rotation around the barrel. The default value advances the animation
## by 0.03 seconds to try to closely synchronize the camera facing frame
## with where it would pop up if you were on the actual barrel from CNZ.
const ANIMATION_OFFSET: float = -0.02

## How many seconds (should be expressed as frames / 60.0) it takes to go around the platform.
## Note that this is the same as the number of frames in the yRotation animation and changing
## this will mean throwing off a bunch of stuff.
const SPINNING_PERIOD: float = 128.0 / 60.0

## Enable the trampoline mode. Needs to be combined with a maxVel to limit the maximum distance traveled.
## MaxVel affects the maximum velocity that can be held at any time which effectively limits the maximum
## distance the gimmick can travel. The closer the current velocity is to the maxVel (absolute), the less impact
## jumping on will have on the velocity.
@export var trampolineMode = false
## Play with this to determine the maximum distance the barrel can travel. It's going to take trial and error, sorry.
@export var maxVel = 480.0

## Don't mess with the spring constants and/or decay values unless you're preparred to spend a long time tinkering.
## springConstantLoaded determines the force at which the spring bounces back when the energy in the spring is at its maximum.
@export var springConstantLoaded = 2.0
## springConstantUnloaded determines the force at which the spring bounces back when the energy in the spring is at 0
@export var springConstantUnloaded = 5.0
## decayLoaded determines how quickly the spring loses energy when the energy in the spring is at its maximum.
@export var decayLoaded = 0.3
## decayUnloaded determines how quickly the spring loses energy when the energy in the spring is at 0
@export var decayUnloaded = 1.0
## influence determines how much energy the player's directional influence imparts
@export var influence = 1.0
## impartFactor determines how much the motion of the platform impacts the player when they jump off
@export var impartFactor = 0.8

# Calcuated based on max velocity, load energy is the amount of energy at which the Loaded constants have full influence
var loadEnergy

# Vertical _look_direction; depends on how many players are holding up/down (0.0 / 1.0 / -1.0)
var _look_direction: float = 0.0
# origin point of the platform, used for spring calculations... should probably always be 0
#var _origin = 0 #currently unused
# y velocity of the platform, moves the platform, determines current energy in the platform when combined with difference between current position and origin
var _yVel = 0
# where the platform is in relation to its origin as a float value. Maybe unnecessary? Either way I'm using it.
var _realY = 0.0
# The physical parts of the bodies that move separate from the main node
@onready var body = $Bodies

# The portions of the gimmick that are AnimatableBody2D need to be manually
# repositioned once we move the the barrel due to an annoying glitch in Godot.
# See: https://github.com/godotengine/godot/issues/58269
@onready var bodies_to_update: Array[AnimatableBody2D] = [$Bodies/ActiveBody, $Bodies/InactiveBody]

var _players: Array[PlayerChar] = []

const _GIMMICK_VAR_Z_INDEX: String = "CNZBarrel_z_height"
const _GIMMICK_VAR_RADIUS: String = "CNZBarrel_radius"
const _GIMMICK_VAR_PHASE: String = "CNZBarrel_phase"

class _ActiveBody extends AnimatableBody2D:
	func physics_collision(player: PlayerChar, hit_vector: Vector2) -> void:
		if hit_vector.y > 0.0 and player.ground:
			get_parent().get_parent().attach_player(player)


func _ready():
	bodies_to_update[0].set_script(_ActiveBody)
	loadEnergy = 0.25 * (maxVel ** 2)
	
	# Sanity checks (the outer assert is there so that in release builds
	# the whole code inside of it doesn't get emitted as bytecode at all)
	assert((func() -> bool:
		var frames: SpriteFrames = $Bodies/AnimatedSprite2D.sprite_frames
		var sprite_size: Vector2 = frames.get_frame_texture(&"default", 0).get_size()
		
		# Make sure all frames are of the same size
		for i: int in range(1, frames.get_frame_count(&"default")):
			assert(frames.get_frame_texture(&"default", i).get_size() == sprite_size)
		
		# Make sure `MAX_RADIUS` corresponds with the actual sprite width
		assert((MAX_RADIUS + 2.0) * 2 == sprite_size.x)
		
		# Make sure body sizes correspond with the sprite size
		var active_body_size: Vector2 = (($Bodies/ActiveBody/CollisionShape2D as CollisionShape2D).shape as RectangleShape2D).size
		var inactive_body_size: Vector2 = (($Bodies/InactiveBody/CollisionShape2D as CollisionShape2D).shape as RectangleShape2D).size
		assert(active_body_size.x == sprite_size.x)
		assert(inactive_body_size.x == sprite_size.x)
		assert(active_body_size.y + inactive_body_size.y == sprite_size.y)
		
		return true
	).call())

func impart_force(velocityChange):
	_yVel = clamp(_yVel + velocityChange, -maxVel, maxVel)

func attach_player(player: PlayerChar):
	# If the player is already in the array, reject the attachment attempt.
	if player in _players:
		return
	
	_players.append(player)
	player.set_active_gimmick(self)
	
	player.set_state(PlayerChar.STATES.GIMMICK)
	var animator: PlayerCharAnimationPlayer = player.get_avatar().get_animator()
	var player_radius: float = clampf(player.global_position.x - body.global_position.x, -MAX_RADIUS, MAX_RADIUS)
	var player_phase: float = 0.0
	animator.play(&"yRotation")
	if player_radius < 0.0:
		player_radius = -player_radius
		player_phase = PI
		animator.advance(ANIMATION_OFFSET)
	player.set_gimmick_var(_GIMMICK_VAR_Z_INDEX, z_index)
	player.set_gimmick_var(_GIMMICK_VAR_RADIUS, player_radius)
	player.set_gimmick_var(_GIMMICK_VAR_PHASE, player_phase)
	
	if trampolineMode:
		# Believe it or not, it really is this simple.
		impart_force(110.0)

	player.set_direction(PlayerChar.DIRECTIONS.RIGHT)

	# Prevents player from clipping on walls while they are on the fringes of the gimmick
	player.allowTranslate = true

func detach_player(player: PlayerChar, index: int):
	player.set_z_index(player.get_gimmick_var(_GIMMICK_VAR_Z_INDEX))
	_players.remove_at(index)
	
	if player.get_state() == PlayerChar.STATES.DIE:
		player.get_avatar().get_animator().play(&"die")
	else:
		player.allowTranslate = false
	
	player.unset_active_gimmick()
	
	# Clamp position to prevent zips on exit
	var radius: float = MAX_RADIUS - player.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL).x / 2.0
	var bodies_x: float = body.global_position.x
	player.global_position.x = clampf(player.global_position.x, bodies_x - radius, bodies_x + radius)

func set_anim(player: PlayerChar, look_direction: float):
	var animator = player.get_avatar().get_animator()
	var curAnim = animator.get_assigned_animation()
	
	var targetAnim: StringName = [&"yRotationLookUp", &"yRotation", &"yRotationLookDown"][int(look_direction) + 1]
	if targetAnim != curAnim:
		var seekTime = animator.get_current_animation_position()
		animator.play(targetAnim)
		animator.advance(seekTime)
		if look_direction > 0.0:
			player.set_predefined_hitbox(PlayerChar.HITBOXES.CROUCH)
			# TODO: Perhaps we should add a method in `PlayerChar` to access the hitbox body
			player.get_node(^"HitBox").position = player.hitBoxOffset.crouch
		else:
			player.get_node(^"HitBox").position = player.hitBoxOffset.normal
			player.set_predefined_hitbox(PlayerChar.HITBOXES.NORMAL)

func _process(delta):
	_look_direction = 0.0

	# We loop backwards so that if we detach a player, they won't affect the index of the next player	
	for index: int in range(_players.size() - 1, -1, -1):
		# Determine inputs, once it's available change player animations
		# Note that we only care if one player is holding a _look_direction even if they
		# are fighting eachother and only the _look_direction of current travel matters.
		var player: PlayerChar = _players[index]
		var player_look_direction: float = signf(player.get_y_input())
		
		set_anim(player, player_look_direction)
		# Don't let AI players conflict with human player inputs
		if player.playerControl != 0:
			_look_direction += player_look_direction
		
		# If the player is closer to the center, the influence of their phase is diminished.
		player.z_index = z_index + 2.0 * player.get_gimmick_var(_GIMMICK_VAR_RADIUS) * -sin(player.get_gimmick_var(_GIMMICK_VAR_PHASE))

		if player.any_action_pressed():
			detach_player(player, index)
			# Whoa, jump!
			player.action_jump("roll", true, false)
			
			# Jump should never go downwards
			player.movement.y = minf(player.movement.y + _yVel * impartFactor, 0.0)
			# pop the player up a bit to make sure they don't make immediate contact again.
			if _yVel > 0.0:
				player.position.y -= _yVel * delta + 10.0
			player.queue_redraw()
		
		elif player.get_state() != PlayerChar.STATES.GIMMICK:
			detach_player(player, index)
	
	for anim_body in bodies_to_update:
		anim_body.global_position = body.global_position

func _physics_process(delta):
	if trampolineMode:
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
		# Also, holding against the _look_direction of travel has no effect
		if _realY > 0.0 and _yVel < 0.0 and _look_direction < 0.0:
			_yVel = clampf(_yVel - (180.0 * delta), -maxVel, maxVel)
			influenced = true
		elif _realY < 0 and _yVel > 0 and _look_direction > 0.0:
			_yVel = clampf(_yVel * (1 + (influence * delta)), -maxVel, maxVel)
			_yVel = clampf(_yVel + (180.0 * delta), -maxVel, maxVel)
			influenced = true

		_yVel += accelerationFactor * delta
		_realY += _yVel * delta

		if !influenced:
			_yVel = _yVel * (1 - (decay * delta))

		# We move the bodies rather than the node. The bodies has all the physical components of the gimmick,
		body.position.y = floorf(_realY)
	
	for player: PlayerChar in _players:
		var phase: float = player.get_gimmick_var(_GIMMICK_VAR_PHASE) + (delta / SPINNING_PERIOD) * 2.0 * PI
		player.set_direction_signed(1.0, false)
		player.set_gimmick_var(_GIMMICK_VAR_PHASE, phase)
		player.global_position = Vector2(
			floorf(body.global_position.x + player.get_gimmick_var(_GIMMICK_VAR_RADIUS) * cos(phase)),
			floorf(body.global_position.y - player.get_predefined_hitbox(PlayerChar.HITBOXES.NORMAL).y / 2.0 - 1.0))
		match player.get_state():
			PlayerChar.STATES.DIE, PlayerChar.STATES.HIT:
				pass
			_:
				player.movement = Vector2.ZERO
		# XXX need to figure out why player 2 is mispositioned while this gimmick is moving quickly
		player.get_camera().update()
	
	for anim_body in bodies_to_update:
		anim_body.global_position = body.global_position
