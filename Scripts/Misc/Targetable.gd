class_name Targetable extends StaticBody2D

enum TARGETABLE_TAGS {
	NONE = 0,
	INTERACTIVE = 1 << 0, # Targets for things like springs
	ENEMY = 1 << 1,
	DESTRUCTABLE = 1 << 2
}

## If low priority is chosen, then this target will never be picked over targets lacking
## this flag. Useful if you have a bunch of destructibles in an area with targets that a player is
## more likely to want to target with things like weapons, attacks, homing attack, etc.
## NOTE: Not Implemented yet
@export var low_priority: bool = false

@export_flags("Interactive", "Enemy", "Destructible") var target_tags: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
