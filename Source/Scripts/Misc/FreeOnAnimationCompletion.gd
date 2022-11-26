extends AnimatedSprite

# animation behaviours, if you want some specific behaviours you can program them with this
var behaviour = 0
enum TYPE {NORMAL, FOLLOW_WATER_SURFACE}

func _ready():
	playing = true
	if behaviour == 0:
		set_process(false)

func _process(_delta):
	match(behaviour):
		TYPE.FOLLOW_WATER_SURFACE:
			if Global.waterLevel != null:
				global_position.y = Global.waterLevel-16

func _on_animation_finished():
	queue_free()
