## Base class for [ZoomTubeEnd] and [ZoomTubeConnector].
## Author: Stanislav Gromov.[br]
## Thanks to:[br]
## * Renhoex - original zoom tube implementation (although the current one
##   is a full rewrite).[br]
## * DimensionWarped - coding help and design guidance.
class_name ZoomTubeJoint extends ZoomTubeBase


func _handle_connection_change(end_name: String, old_value: ZoomTube, new_value: ZoomTube) -> ZoomTube:
	if old_value != null:
		old_value.disconnect_from_joint(self)
	var var_postfix: String = ("_" + end_name) if end_name != "" else ""
	if new_value != null:
		set("_connected_end_idx" + var_postfix, new_value.connect_to_joint(self, _get_connection_point(end_name)))
	
	# deferred call, so the function is called after `_connected_to_*` is set
	_force_configuration_warnings_update.call_deferred()
	
	return new_value

func _is_opened_as_scene() -> bool:
	return get_parent() == get_viewport()

# HACK: Apparently `update_configuration_warnings()` won't call
# `_get_configuration_warnings()`, unless we modify the tree
func _force_configuration_warnings_update() -> void:
	var node: Node = Node.new()
	add_child(node)
	node.free()
	
	update_configuration_warnings()

# TODO: Use `@abstract` annotation once we upgrade to Godot 4.5 or higher.
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#abstract-classes-and-methods
## Accepts the player from a [ZoomTube].
func accept_player_from_tube(_player: PlayerChar, _tube: ZoomTube) -> void:
	pass

## Disconnects this [ZoomTubeJoint] node from a [ZoomTube].
func disconnect_from_tube(_tube: ZoomTube) -> void:
	pass

func _get_connection_point(end_name: String) -> Vector2:
	return Vector2.ZERO
