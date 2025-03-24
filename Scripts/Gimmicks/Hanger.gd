extends Area2D

# Array of Arrays for each player interacting with the gimmick...
# Please don't access/mutate this array directly, use the relevant functions
# or add new ones where needed.
#
# [n][0] - player's object id
#
# [n][1] - player's contact point
#          note: null until the player actually grabs somewhere and null after
#          the player disconnects
#
# [n][2] - player's most recent disconnect time in msec since engine start (used to prevent double grab)
#          note: null if player hasn't disconnected before in this contact session
#
# [n][3] - player's most recent connect time in msec -- prevent player from disconnecting due to ground touching
#          if they were picked up in the last few frames from the ground.
#
# XXX - consider a statically sized array that knows the count of players at the start (possibly stored in globals?)
# for optimal efficiency.
var players = []

# How many players are currently connected. private, please use accessor to read.
var _playerContacts = 0

# Sets the distance from the center of the hitbox (vertically) at which the contact may occur
const _CONTACT_DISTANCE = 17

# Twelve frames must pass between regrabs
const _CONTACT_TIME_LIMIT = ceil(12.0 * (1000.0 / 60.0))

# If true, the player can drop through by holding down, bypassing the grab.
@export var holdDownToDrop = false

# If true, player will grab the center point of the hanger every time.
# otherwise the player grabs the bar at the position that the player is located
# at making contact.
@export var setCenter = false

# If false, the player can grab the bar while moving upwards. Otherise the bar
# is only caught while the player is falling.
@export var onlyActiveMovingDown = true

# If false, the player may turn around freely while on the bar. Otherwise the
# player's direction is locked to the same direction that they first contacted
# the hanger in.
@export var lockPlayerDirection = true

# Can pick up from ground
@export var groundPickup = false

# Changes some behaviors of how the controls work. Only gets set by parent object
# if the hanger is owned by a player.
var playerCarryAI = false

# Optionally set sound to play when making contact
@export var grabSound = preload("res://Audio/SFX/Player/Grab.wav")

func _ready():
	$Grab.stream = grabSound

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
	
# Use to get the player contact position at the index of the array.
# Returns the contact position if the index isn't out of bounds, otherwise returns null.
func get_player_contact(index):
	if players.size() >= index + 1:
		return players[index][1]
	return null
	
func set_player_contact(index, value):
	if players.size() >= index + 1:
		players[index][1] = value
		return
	printerr("Tried to set player contact to out of bounds index ", index)

# Use to set the disconnect time for the player at the index of the array.
# Always sets to the current engine time in millisecond ticks
func set_player_disconnect_time(index):
	if players.size() >= index + 1:
		players[index][2] = Time.get_ticks_msec()
		#print("players[index][2] = ", players[index][2])
		return
	printerr("Attempted to set player disconnect time on invalid index")

# Use to check if the elapsed disconnected time for the player at the index of
# the array exceeds the elapsed time requirement for regrabbing.
# Returns true if the time of last disconnect is set and elapsed or if no disconnects are already set.
# Returns false if the time of last disconnect is set not yet elapsed.
# Returns false if the index is out of bounds
func is_player_disconnect_time_elapsed(index):
	if players.size() < index + 1:
		printerr("Attempted to access player disconnect on invalid index")
		# returning false just so there is something to consume
		return false
	if players[index][2] == null:
		return true
		
	var curTime = Time.get_ticks_msec()
	var elapsedTime = curTime - players[index][2]
	if elapsedTime > _CONTACT_TIME_LIMIT:
		#print ("elapsed time checked - ", elapsedTime)
		return true
	return false

# Returns the count of players contacting with the hanger. Used by external scripts.
func get_player_contacting_count():
	return _playerContacts
	
func physics_process_connected(_delta, player, index):
	if player.ground:
		disconnect_grab(player, index, false)
		return

	# XXX In the future, we should make the states themselves have properties for whether or not
	# they allow interaction with gimmicks that use the player's hands so that we don't have to
	# make up a list of states for stuff like this every time.
	if player.currentState != player.STATES.AIR and player.currentState != player.STATES.JUMP and player.currentState != player.STATES.GLIDE and player.currentState != player.STATES.FLY:
		disconnect_grab(player, index, false)
		return

	# For some reason all the movement logic is in here?
	# jump and air states don't change animation, so no need for a new state. Just
	# set the animation and convert out of any unusual states into AIR.
	player.animator.play("hang")
	player.set_state(player.STATES.AIR)
	player.airControl = true
	
	# Perform just the functional parts  of the connect script that move the
	# player into position.
	var getPose = (global_position+get_player_contact(index).rotated(rotation) + Vector2(0.0, player.currentHitbox.NORMAL.y / 2.0)).round()
		
	# verify position change won't clip into objects
	if !player.test_move(player.global_transform,getPose-player.global_position):
		player.global_position = getPose
		player.movement = Vector2.ZERO
				
	player.cam_update()
	
func physics_process_disconnected(_delta, player, index):
	# we use parent only for picking up off ground
	var parent = get_parent()
	if (!groundPickup and player.ground):
		return
		
	if !check_grab(player, index):
		return

	# If it's going to pick a player up off the ground, it has to be moving upwards.
	if player.ground and parent.movement.y > 0:
		return
	
	# XXX This a Tails centric hack right now. I don't like it. It makes Tails
	# move upwards to avoid disconnecting immediately.
	if player.ground:
		player.set_state(player.STATES.AIR)
		player.global_position.y -= 6
		parent.global_position.y -= 6
		
	connect_grab(player, index)

# This function is responsible for connecting grabs in the first place *and* for
# disconnecting grabs if the player contacts the ground while grabbing.
func _physics_process(delta):
	_playerContacts = 0
	
	for index in players.size():
		var player = get_player(index)
		
		if get_player_contact(index) != null:
			_playerContacts += 1
			physics_process_connected(delta, player, index)
			continue
		else:
			physics_process_disconnected(delta, player,index)
			continue

# This function is responsible for positioning the player while the player is connected to the hanger.
# It also sets animation... that seems wrong, animation should be set on first contact, not repeatedly.
func connect_grab(player, index):
	# Iterate player contacts by one. Only really used by Tails fly-carry right now, but who knows,
	# maybe it could be part of a weight mechanic for some gimmick later.
	_playerContacts += 1
	
	# set contact point (start grab)
	if get_player_contact(index) == null:
		$Grab.play()
		player.set_active_gimmick(self)
		var calcDistance = _CONTACT_DISTANCE+(19-player.currentHitbox.NORMAL.y)
		if !setCenter:
			set_player_contact(index, Vector2(player.global_position.x-global_position.x,calcDistance))
		else:
			set_player_contact(index, Vector2(0,calcDistance))
				
	var getPose = (global_position+get_player_contact(index).rotated(rotation)).round()
		
	# verify position change won't clip into objects
	#if !player.test_move(player.global_transform,getPose-player.global_position):
	player.global_position = getPose
	player.movement = Vector2.ZERO
				
	player.cam_update()

	# lock player direction if that toggle is set.
	if lockPlayerDirection:
		player.stateList[player.STATES.AIR].lockDir = true	

func disconnect_grab(player, index, deliberate, jumpUpwards=false):
	# Don't bother disconnecting if they aren't already connected.
	if get_player_contact(index) == null:
		return

	#print("invoking set_player_disconnect_time")
	set_player_disconnect_time(index)
	
	player.animator.play("roll")
	player.set_state(player.STATES.JUMP)
	
	if deliberate:
		if (jumpUpwards):
			player.movement.y = -player.jmp/2
		else:
			player.movement.y = player.jmp/16
		# set ground speed to 0 to stop rolling going nuts
		player.groundSpeed = 0

	# Unlock air direction if we previous locked it.
	if lockPlayerDirection:
		player.stateList[player.STATES.AIR].lockDir = false

	# unset player variable for pole XXX want to switch to dictionary later
	player.unset_active_gimmick()
	# unset the contact point for the player XXX want to switch to mutator function later
	set_player_contact(index, null)
	
	# lower playerContacts value one... I guess in case anything else accesses this in the same process pass.
	_playerContacts -= 1
	
func checkPlayerDisconnectByAction(player):
	if playerCarryAI:
		if player.is_down_held() and player.any_action_pressed():
			return 1 # a retval of 1 is a jump up
	elif player.any_action_pressed():
		if player.is_down_held():
			return 2 # a retval of 2 is a jump down
		return 1
	return 0 # a retval of 0 is a no disconnect

func _process(_delta):
	# All this process does is disconnects a grab if the player who owns it makes a deliberate action
	# to jump off of the hanger.
	for index in players.size():
		var jumpUp
		var player = players[index][0]
		
		# verify state is valid for grabbing and not on floor
		if player.ground or player.currentState != player.STATES.AIR:
			continue

		# We don't need to do anything if the player isn't jumping off
		jumpUp = checkPlayerDisconnectByAction(player)
		if jumpUp == 0:
			continue

		# We don't need to do anything if the player isn't grabbing anything
		if !check_grab(player,index):
			continue

		# Disconnect grab can either jump up or go down depending on player input and whether they
		# were being carried by AI when they made that input.
		disconnect_grab(player, index, true, jumpUp == 1)

func check_grab(player, index):
	# We always return a grab if the player's contact point is already set.
	if get_player_contact(index) != null:
		return true
	
	# We never grab when the poleID is already on a valid poll (self isn't a valid pole... how this can get set I'm not sure)
	if player.get_active_gimmick() != null and player.get_active_gimmick() != self:
		return false

	# We don't grab if the player is moving upwards and the pole is set not to grab upward moving players.
	if player.movement.y < 0 and onlyActiveMovingDown:
		return false
		
	# We don't grab when the player is outside of the allowed contact distance
	if (player.global_position.y - global_position.y) < Vector2(0, _CONTACT_DISTANCE).rotated(rotation).y:
		return false
		
	# We don't grab when holdDownToDrop is active and down is held
	if holdDownToDrop and player.is_down_held():
		return false

	# There haven't been enough ticks since the last grab ended, so we aren't regrabbing
	if !is_player_disconnect_time_elapsed(index):
		return false

	# If we didn't hit any of the ejection conditions then we are good to grab
	return true

func _on_Hanger_body_entered(body):
	# check that parent isn't going to be carried in the case of a player that generates their own hanger (IE Tails)
	if body == get_parent():
		return

	# If the player isn't in the players array, create a record for the player and add it to the array.
	if find_player(body) == -1:
		var player_rep = [body, null, null, null]
		players.append(player_rep)

func _on_Hanger_body_exited(body):
	remove_player(body)

func remove_player(player):
	# remove player from contact point
	var getIndex = find_player(player)

	# no player found
	if (getIndex == -1):
		return
		
	# Remove the player
	players.remove_at(getIndex)
	
# It may be prudent to come back later and refactor this gimmick to use these instead of its own
# process/physics process for player specific actions.
func player_process(player, delta):
	pass
	
func player_physics_process(player, delta):
	pass

# I'll probably need to lock the gimmick here to prevent the same bar from just immediately being
# grabbed if the player is launched off with a spring or something.
func player_force_detach_callback(player):
	pass
