## Base class with common stuff for all ZoomTube-related nodes.
## Author: Stanislav Gromov.[br]
## Thanks to:[br]
## * Renhoex - original zoom tube implementation (although the current one
##   is a full rewrite).[br]
## * DimensionWarped - coding help and design guidance.
class_name ZoomTubeBase extends ConnectableGimmick


# Name of the gimmick variable responsible for the direction
# the player travels through the zoom tube.
const _TRAVEL_DIRECTION_GIMMICK_VAR: String = "zoom_tube_travel_direction"

# Name of the gimmick variable storing the PathFollow2D node
# for following the tube's Path2D.
const _PATH_FOLLOWER_GIMMICK_VAR: String = "zoom_tube_path_follower"


func player_force_detach_callback(player: PlayerChar) -> void:
	var follower: PathFollow2D = player.get_gimmick_var(_PATH_FOLLOWER_GIMMICK_VAR)
	follower.queue_free()
	player.unset_gimmick_var(_PATH_FOLLOWER_GIMMICK_VAR)
	player.unset_gimmick_var(_TRAVEL_DIRECTION_GIMMICK_VAR)
