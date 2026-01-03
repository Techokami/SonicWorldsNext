# TODO: This may be an ideal candidate for using the `@abstract` annotation
# once we upgrade to Godot 4.5 or higher.
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#abstract-classes-and-methods

## Abstract connectable gimmick class — use this on all gimmicks that you want
## to bind the player to exclusively. Exclusive binding is usually going to
## be more reliable than attempting to bind via a gimmick specific player list.
class_name ConnectableGimmick extends Node2D

## This function will be invoked at the end of the player [method _process].
## Treat this as a player process function specific to your gimmick. You may
## be able to work around things in a way that you don't actually need this
## and can just use your gimmick's [method _process] function, and that's ok!
func player_process(_player : PlayerChar, _delta : float) -> void:
	pass

## Same as [method player_process], but for the [method _physics_process]
## instead. As with [method player_process], you may be able to handle
## everything you want within your gimmick's [method _process] function.[br]
## [param _player] — player whose process function is responsible for running this.[br]
## [param _delta] — how much time has passed between last frame and this one in seconds.
func player_physics_process(_player : PlayerChar, _delta : float) -> void:
	pass

## Some objects may for the player to detach from their current gimmick either
## in order to attach to another one or just because they want to make sure the
## player is clean to take other actions. When that happens, this callback
## function will be ran. You can use it to clean up player state among other
## things.[br]
## [param _player] — player being detached by force.
func player_force_detach_callback(_player : PlayerChar) -> void:
	pass

## When a player is attached to your gimmick this will excute whenever an animation
## that player is playing reaches its end. Override this function and you can then
## take action on the player when that happens.[br]
## [param _player] — which player entity finished their animation.[br]
## [param _animation] — name of the animation that finished.
func handle_animation_finished(_player : PlayerChar, _animation : String) -> void:
	pass
