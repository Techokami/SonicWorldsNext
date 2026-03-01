## Serves as a connector for zoom tubes.[br]
## Author: Stanislav Gromov.[br]
## Thanks to:[br]
## * Renhoex - original zoom tube implementation (although the current one
##   is a full rewrite).[br]
## * DimensionWarped - coding help and design guidance. 
@tool
class_name ZoomTubeConnector extends ZoomTubeJoint


# Name of the gimmick variable that stores the tube
# the player has entered the connector node from.
const _PREVIOUS_TUBE_GIMMICK_VAR: String = "zoom_tube_connector_previous_tube"

## Defines types of logic for handling player getting out of the connector.
enum SPLIT_TYPES {
	## Direction is determined by weighted random selection based on chances
	## (weights) specified in variables [member split_chance_north],
	## [member split_chance_south],  [member split_chance_east] and
	## [member split_chance_west]. The side the player has entered
	## into the connector from is excluded from selection.[br]
	## See [method RandomNumberGenerator.rand_weighted] for the details about
	## how weights in weighted random selection work.
	RANDOM,
	
	## Direction is determined by the player's input. For example,
	## if the [kbd]↑[/kbd] button is pressed, the player goes out
	## from the northern side, [kbd]↓[/kbd] - from the southern side, etc.
	PLAYER_INPUT
}


static var _rng_instance: RandomNumberGenerator = RandomNumberGenerator.new()


@export_group("North side")
## Tube this node is connected to from the northern side.
@export var connected_to_north: ZoomTube:
	set(tube):
		if tube == null:
			split_chance_north = 0.0
		connected_to_north = _handle_connection_change(connected_to_north, tube)
## Chance of randomly getting out from the northern side.
@export var split_chance_north: float = 50.0:
	set(value):
		split_chance_north = value
		_update_hints()

@export_group("South side")
## Tube this node is connected to from the southern side.
@export var connected_to_south: ZoomTube:
	set(tube):
		if tube == null:
			split_chance_south = 0.0
		connected_to_south = _handle_connection_change(connected_to_south, tube)
## Chance of randomly getting out from the southern side.
@export var split_chance_south: float = 50.0:
	set(value):
		split_chance_south = value
		_update_hints()

@export_group("East side")
## Tube this node is connected to from the eastern side.
@export var connected_to_east: ZoomTube:
	set(tube):
		if tube == null:
			split_chance_east = 0.0
		connected_to_east = _handle_connection_change(connected_to_east, tube)
## Chance of randomly getting out from the eastern side.
@export var split_chance_east: float = 50.0:
	set(value):
		split_chance_east = value
		_update_hints()

@export_group("West side")
## Tube this node is connected to from the western side.
@export var connected_to_west: ZoomTube:
	set(tube):
		if tube == null:
			split_chance_west = 0.0
		connected_to_west = _handle_connection_change(connected_to_west, tube)
## Chance of randomly getting out from the western side.
@export var split_chance_west: float = 50.0:
	set(value):
		split_chance_west = value
		_update_hints()

@export_group("")

## Type of logic for handling player getting out of the connector.[br]
## See also: [enum SPLIT_TYPES].
@export var split_type: SPLIT_TYPES = SPLIT_TYPES.RANDOM:
	set(value):
		split_type = value
		_update_hints()

## If true and [code]split_type == SPLIT_TYPES.PLAYER_INPUT[/code], shows
## arrow sprites, hinting that player input is required to proceed.
@export var show_hint_arrows: bool = false

## Size of entrance and exit areas.
@export var hitbox_size: Vector2 = Vector2(4.0, 4.0)


var _timer: Timer


## See [method ZoomTubeJoint.accept_player_from_tube].
func accept_player_from_tube(player: PlayerChar, tube: ZoomTube) -> void:
	# unset the tube first, so its `player_force_detach_callback()` won't get called
	player.unset_active_gimmick()
	
	# remember the previous pipe - we'll need it later to make sure
	# the player won't randomly re-enter that pipe
	if split_type == SPLIT_TYPES.RANDOM:
		player.set_gimmick_var(_PREVIOUS_TUBE_GIMMICK_VAR, tube)
	
	player.set_active_gimmick(self)
	_add_player(player)

## See [method ZoomTubeJoint.disconnect_from_tube].
func disconnect_from_tube(tube: ZoomTube) -> void:
	if tube == connected_to_north:
		connected_to_north = null
	elif tube == connected_to_south:
		connected_to_south = null
	elif tube == connected_to_east:
		connected_to_east = null
	elif tube == connected_to_west:
		connected_to_west = null
	else:
		@warning_ignore("assert_always_false") assert(false)

func player_physics_process(player: PlayerChar, _delta: float) -> void:
	var tube: ZoomTube = null
	match split_type:
		
		SPLIT_TYPES.PLAYER_INPUT:
			if player.is_up_held() and connected_to_north != null:
				tube = connected_to_north
			elif player.is_down_held() and connected_to_south != null:
				tube = connected_to_south
			elif player.is_right_held() and connected_to_east != null:
				tube = connected_to_east
			elif player.is_left_held() and connected_to_west != null:
				tube = connected_to_west
		
		_: # SPLIT_TYPES.RANDOM - perform a weighted random selection
			var options: Dictionary = { # TODO: Use a typed dictionary when we upgrade to Godot 4.4 or later
				connected_to_north: split_chance_north,
				connected_to_south: split_chance_south,
				connected_to_east:  split_chance_east,
				connected_to_west:  split_chance_west
			}
			options.erase(null)
			options.erase(player.get_gimmick_var(_PREVIOUS_TUBE_GIMMICK_VAR))
			var r: int = _rng_instance.rand_weighted(options.values())
			if r != -1:
				tube = options.keys()[r]
	
	if tube != null:
		_remove_player(player)
		player.unset_gimmick_var(_PREVIOUS_TUBE_GIMMICK_VAR)
		tube.accept_player_from_joint(player, self, split_type != SPLIT_TYPES.RANDOM)
	else:
		player.global_position = global_position

func player_force_detach_callback(player: PlayerChar) -> void:
	super(player)
	_remove_player(player)
	player.unset_gimmick_var(_PREVIOUS_TUBE_GIMMICK_VAR)


func _ready() -> void:
	if Engine.is_editor_hint():
		_update_hints()
	else:
		if split_type == SPLIT_TYPES.PLAYER_INPUT and show_hint_arrows:
			$Hints.visible = false
			var labels: Node2D = $Hints/Labels
			var arrows: Node2D = $Hints/Arrows
			var connected: bool
			for end_name: String in [ "North", "South", "East", "West" ]:
				connected = (get("connected_to_" + end_name.to_lower()) != null)
				(labels.get_node(end_name) as Label).visible = connected
				(arrows.get_node(end_name) as Sprite2D).visible = connected
			
			_timer = Timer.new()
			_timer.wait_time = 0.5
			_timer.timeout.connect(_toggle_hints)
			add_child(_timer)
		
		else:
			$Hints.queue_free()

func _add_player(player: PlayerChar) -> void:
	if show_hint_arrows and player == Global.players[0]:
		_toggle_hints()
		_timer.start()

func _remove_player(player: PlayerChar) -> void:
	if show_hint_arrows and player == Global.players[0]:
		_timer.stop()
		$Hints.visible = false

func _toggle_hints() -> void:
	$Hints.visible = not $Hints.visible

func _count_connected_ends() -> int:
	return 4 - [connected_to_north, connected_to_south, connected_to_east, connected_to_west].count(null)

func _update_hints() -> void:
	if _is_opened_as_scene():
		return
	
	# deferred call, in case this code is executed before the node is ready
	(func() -> void:
		# if the split mode is `RANDOM`, don't show the weights if only 2 sides are
		# connected (the weights are meaningless in that case, as one tube always
		# gets excluded from the choice and the other one always gets chosen);
		# otherwise, if the mode is `PLAYER_INPUT`, the labels are always shown,
		# as they're reused as a background for the arrows
		var display_labels: bool = split_type != SPLIT_TYPES.RANDOM or _count_connected_ends() > 2
		
		for n: Node in $Hints/Labels.get_children():
			assert(n is Label)
			n.text = ("%.f" % get("split_chance_" + n.name.to_lower())) if split_type == SPLIT_TYPES.RANDOM else ""
			n.visible = display_labels and get("connected_to_" + n.name.to_lower()) != null
		
		for n: Node in $Hints/Arrows.get_children():
			assert(n is Sprite2D)
			n.visible = (split_type == SPLIT_TYPES.PLAYER_INPUT) and get("connected_to_" + n.name.to_lower()) != null
	).call_deferred()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if (not _is_opened_as_scene() and _count_connected_ends() < 2):
		warnings.append(
			"At least 2 ends must be connected to pipes for the connector to function properly.\n" +
			"Consider specifying connected tubes in 'connected_to_*' variables."
		)
	return warnings
