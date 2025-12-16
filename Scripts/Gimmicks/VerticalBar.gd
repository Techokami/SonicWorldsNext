extends ConnectableGimmick

## Vertical Swinging Bar from Mushroom Hill Zone
## Author: DimensionWarped

## Sound to play when the bar is grabbed
@export var grabSound = preload("res://Audio/SFX/Player/Grab.wav")
## How many times to spin around the bar before launching
@export var rotations = 1
## How fast the player needs to be going to catch the bar
@export var grabSpeed = 300
## How fast to launch the player if the mode is constant
@export var launchSpeed = 720
## How fast to launch the player if the mode is multiply
@export var launchMultiplier = 1.5
## Maximum speed to allow the player to launch when in multiply
@export var launchMultiMaxSpeed = 900

enum LAUNCH_MODES {CONSTANT, MULTIPLY}
## The CONSTANT launch mode will always launch the player with a set speed based on launchSpeed
## The MULTIPLY launch mode will launch the player at a multiple of their incoming velocity limit_length
##              to a given max value.
@export var launchMode: LAUNCH_MODES = LAUNCH_MODES.MULTIPLY  # Keep these in the same order as the above enum # (int, "constant", "multiply")

## Called when the node enters the scene tree for the first time.
func _ready():
	$Grab.stream = grabSound

## All we do here is check if anyone needs to get connected
func _process(_delta: float) -> void:
	var players_to_check = $VerticalBarArea.get_overlapping_bodies()
	for player : PlayerChar in players_to_check:
		if check_grab(player):
			connect_player(player)
			continue

## Binds the player to the vertical bar gimmick
func connect_player(player: PlayerChar):
	# attmept to connect to the gimmick. If failed, we give up this attempt.
	if player.set_active_gimmick(self) == false:
		return
		
	var animator = player.get_avatar().get_animator()

	$Grab.play()
	if player.movement.x > 0:
		player.set_direction(PlayerChar.DIRECTIONS.RIGHT)
		animator.reset_loops() # We need to count loops, so it's time to reset them.
		animator.play("grabVerticalBar")
	else:
		player.set_direction(PlayerChar.DIRECTIONS.LEFT)
		animator.reset_loops() # We need to count loops, so it's time to reset them.
		animator.play("grabVerticalBarOffset")

	player.set_state(PlayerChar.STATES.GIMMICK)
	player.set_gimmick_var("VerticalBarSpeedAtEntry", player.groundSpeed)
			
	# Drop all the speed values to 0 to prevent issues.
	player.groundSpeed = 0
	player.movement.x = 0
	player.movement.y = 0
	player.get_camera().update()
	player.global_position.x = get_global_position().x
	
	player.set_active_gimmick(self)
	
## Locks the gimmick for the player - prevents the player from immediately
## reconnecting after launching off the gimmick.
func temp_lock_gimmick(player: PlayerChar) -> void:
	var unlock_func = func ():
		player.clear_single_locked_gimmick(self)
	
	var timer:SceneTreeTimer = get_tree().create_timer(0.25, false)
	timer.timeout.connect(unlock_func, CONNECT_DEFERRED)
	
	player.add_locked_gimmick(self)
	pass

## Disconnects the player from the bar. If we came in here due to the end
## of the animation, 
func disconnect_player(player: PlayerChar, do_launch: bool = true):
	# If we aren't doing the launch we probably either jumped off or got hit.
	if do_launch:
		if launchMode == LAUNCH_MODES.MULTIPLY:
			player.movement.x = min(launchMultiMaxSpeed, max(-launchMultiMaxSpeed,
			  player.get_gimmick_var("VerticalBarSpeedAtEntry") * launchMultiplier))
		else:
			player.movement.x = launchSpeed * player.get_direction()
		player.movement.y = 0
		player.set_state(PlayerChar.STATES.NORMAL)
	
	player.unset_active_gimmick()
	# Lock the gimmick for a short bit now so that the player can slip past if it fthey launched
	temp_lock_gimmick(player)

## Disconnects either on animation or when the player attempts to jump off
func player_process(player : PlayerChar, _delta : float):
	if player.get_avatar().get_animator().get_loops() >= rotations:
		disconnect_player(player, true)
	
	if player.any_action_pressed():
		# Whoa! JUMP!
		disconnect_player(player, false)
		var sprite: Sprite2D = player.sprite
		player.position.x += (sprite.offset.x / 2.0) # TODO This gimmick should stop faking x position via offsets
		player.action_jump("roll",true, false)

## Checks if the player should grab the bar
func check_grab(player: PlayerChar) -> bool:
	# Don't grab if the gimmick is locked (which it will be for a short time after releasing it)
	if (player.is_gimmick_locked_for_player(self)):
		return false
		
	# Only grab the bar if the player is in a ground state (rolling or running) and speed is above value
	if !(player.is_on_ground()):
		return false
		
	# Skip if already in a special animation state or if the player is jumping
	if (player.get_state() == PlayerChar.STATES.GIMMICK or player.get_state() == PlayerChar.STATES.JUMP):
		return false

	# We never grab the bar unless the player is running fast enough
	if abs(player.get_ground_speed()) < grabSpeed:
		return false

	# We passed all the checks and should grab the bar
	return true

## This will usually only be invoked if the player gets hit or another object
## forces the player off
func player_force_detach_callback(player : PlayerChar):
	disconnect_player(player, false)
	pass
