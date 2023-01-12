extends Area2D
tool

onready var screenSize = get_viewport().size

export (NodePath)var bossPath

export var keepLeftLocked = true
export var keepTopLocked = true

export var keepRightLocked = true
export var keepBottomLocked = true

export var lockLeft = true
export var lockTop = true

export var lockRight = true
export var lockBottom = true


export var ratchetScrollLeft = false
export var ratchetScrollTop = false
export var ratchetScrollRight = false
export var ratchetScrollBottom = false

var bossActive = false

func _on_BoundrySetter_body_entered(body):
	$CollisionShape2D.disabled = true
	# set boundry settings
	if !Engine.editor_hint and !bossActive:
		# Check body has a camera variable
		if (body.get("camera") != null):
			var boss = get_node_or_null(bossPath)
			if boss != null:
				bossActive = true
				# Check if set boundry is true, if it is then set the camera's boundries for each player
				for i in Global.players:
					if lockLeft:
						i.limitLeft = max(global_position.x-screenSize.x/2,Global.hardBorderLeft)
					if lockTop:
						i.limitTop = max(global_position.y-screenSize.y/2,Global.hardBorderTop)
					if lockRight:
						i.limitRight = min(global_position.x+screenSize.x/2,Global.hardBorderRight)
					if lockBottom:
						i.limitBottom = min(global_position.y+screenSize.y/2,Global.hardBorderBottom)
				
				Global.main.set_volume(-50)
				yield(Global.main,"volume_set")
				Global.main.set_volume(0,100)
				
				Global.bossMusic.play()
				boss.active = true
				
				if boss.has_signal("boss_over"):
					boss.connect("boss_over",self,"boss_completed")

func boss_completed():
	Global.bossMusic.stop()
	Global.music.play()
	# set boundries for players
	for i in Global.players:
		if is_instance_valid(i):
			if !keepLeftLocked:
				i.limitLeft = Global.hardBorderLeft
			if !keepTopLocked:
				i.limitTop = Global.hardBorderTop
			if !keepRightLocked:
				i.limitRight = Global.hardBorderRight
			if !keepBottomLocked:
				i.limitBottom = Global.hardBorderBottom
			# set ratchetScrolling
			i.rachetScrollLeft = ratchetScrollLeft
			i.rachetScrollTop = ratchetScrollTop
			i.rachetScrollRight = ratchetScrollRight
			i.rachetScrollBottom = ratchetScrollBottom
