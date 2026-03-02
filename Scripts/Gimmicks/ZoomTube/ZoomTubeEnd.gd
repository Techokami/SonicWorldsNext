## Serves as an entrance/exit point for zoom tubes.[br]
## Author: Stanislav Gromov.[br]
## Thanks to:[br]
## * Renhoex - original zoom tube implementation (although the current one
##   is a full rewrite).[br]
## * DimensionWarped - coding help and design guidance.
@tool
class_name ZoomTubeEnd extends ZoomTubeJoint


## Tube this end node is connected to.
@export var connected_to: ZoomTube = null:
	set(tube): connected_to = _handle_connection_change(connected_to, tube)

## If [code]true[/code], the player can enter the linked tube,
## otherwise it's exit-only.
@export var allow_entry: bool = true:
	set(value):
		allow_entry = value
		if not Engine.is_editor_hint():
			return
		(func() -> void:
			$DirectionArrow/EntryArrow.visible = allow_entry
		).call_deferred()

## Size of entrance and exit areas.
@export var hitbox_size: Vector2 = Vector2(4.0, 4.0)


var _connected_to_mem: ZoomTube = null


## See [method ZoomTubeJoint.accept_player_from_tube].
func accept_player_from_tube(player: PlayerChar, tube: ZoomTube) -> void:
	var follower: PathFollow2D = player.get_gimmick_var(_PATH_FOLLOWER_GIMMICK_VAR)
	player.unset_gimmick_var(_PATH_FOLLOWER_GIMMICK_VAR)
	
	player.set_state(PlayerChar.STATES.ROLL)
	player.movement = Vector2(tube.speed * 60.0, 0.0).rotated(global_rotation)
	follower.queue_free()
	player.sfx[3].play()
	player.unset_active_gimmick()
			
	# before unsetting the direction variable, wait for 1/4 of a second,
	# so the player won't re-enter the same tube right after exiting it
	var tree: SceneTree = get_tree()
	var end_time: int = Time.get_ticks_msec() + (1000 / 4)
	while Time.get_ticks_msec() < end_time:
		await tree.physics_frame
	
	player.unset_gimmick_var(_TRAVEL_DIRECTION_GIMMICK_VAR)

## See [method ZoomTubeJoint.disconnect_from_tube].
func disconnect_from_tube(tube: ZoomTube) -> void:
	assert(connected_to == tube)
	connected_to = null


func _ready() -> void:
	if not Engine.is_editor_hint():
		$Area2D/CollisionShape2D.shape.size = hitbox_size
		$Area2D.connect(&"body_entered", _on_hitbox_enter)
		$DirectionArrow.queue_free()
		set_process(false)

func _process(_delta: float) -> void:
	# Apparently the tube node stays valid even after it's removed in the editor
	# (probably because the user can still undo the removal), and the value
	# in `connected_to` doesn't change (it keeps referencing the removed tube),
	# although, interestingly enough, the editor displays the value
	# of `connected_to` as empty. In order to work around that, we'll have
	# to check the value in `connected_to` on each `_physics_process()` call
	# and set it to `null` when the tube is not in tree.
	if connected_to != null and not connected_to.is_inside_tree():
		_connected_to_mem = connected_to
		connected_to = null
	
	# If the user removed the tube in the scene editor, and then
	# pressed "Undo" (Ctrl+Z), we'll have to restore the connection.
	if _connected_to_mem != null and connected_to == null and _connected_to_mem.is_inside_tree():
		connected_to = _connected_to_mem

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if not _is_opened_as_scene() and connected_to == null:
		warnings.append(
			"This tube joint doesn't have its connection configured.\n" +
			"Consider specifying connected tube in 'connected_to' variable."
		)
	return warnings

func _on_hitbox_enter(player: PlayerChar) -> void:
	if allow_entry and player.get_gimmick_var(_TRAVEL_DIRECTION_GIMMICK_VAR) == null:
		player.set_state(PlayerChar.STATES.GIMMICK)
		player.get_avatar().get_animator().play("roll")
		player.set_ground_speed(4.0 * 60.0)
		connected_to.accept_player_from_joint(player, self)
