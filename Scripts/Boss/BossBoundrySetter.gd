extends Area2D


@onready var screenSize = GlobalFunctions.get_screen_size()

@export_node_path var bossPath

@export var keepLeftLocked = true
@export var keepTopLocked = true

@export var keepRightLocked = true
@export var keepBottomLocked = true

@export var lockLeft = true
@export var lockTop = true

@export var lockRight = true
@export var lockBottom = true


@export var ratchetScrollLeft = false
@export var ratchetScrollTop = false
@export var ratchetScrollRight = false
@export var ratchetScrollBottom = false

var bossActive = false

func _on_BoundrySetter_body_entered(_body: PlayerChar):
	if !Engine.is_editor_hint():
		$CollisionShape2D.set_deferred("disabled",true)
		# set boundry settings
		if !bossActive:
			var boss = get_node_or_null(bossPath)
			if boss != null:
				bossActive = true
				# Check if set boundry is true, if it is then set the camera's boundries for each player
				for i in Global.players:
					if lockLeft:
						i.get_camera().target_limit_left = maxf(global_position.x-screenSize.x/2.0,Global.hardBorderLeft)
					if lockTop:
						i.get_camera().target_limit_top = maxf(global_position.y-screenSize.y/2.0,Global.hardBorderTop)
					if lockRight:
						i.get_camera().target_limit_right = minf(global_position.x+screenSize.x/2.0,Global.hardBorderRight)
					if lockBottom:
						i.get_camera().target_limit_bottom = minf(global_position.y+screenSize.y/2.0,Global.hardBorderBottom)
				
				
				MusicController.play_music_theme(MusicController.MusicTheme.BOSS_THEME)
				boss.active = true
				
				if boss.has_signal("boss_over"):
					boss.connect("boss_over",Callable(self,"boss_completed"))

func boss_completed():
	MusicController.stop_music_theme(MusicController.MusicTheme.BOSS_THEME)
	# set boundries for players
	for i in Global.players:
		if is_instance_valid(i):
			if !keepLeftLocked:
				i.camera.target_limit_left = Global.hardBorderLeft
			if !keepTopLocked:
				i.camera.target_limit_top = Global.hardBorderTop
			if !keepRightLocked:
				i.camera.target_limit_right = Global.hardBorderRight
			if !keepBottomLocked:
				i.camera.target_limit_bottom = Global.hardBorderBottom
			# set ratchetScrolling
			var camera: PlayerCamera = i.get_camera()
			camera.ratchet_scroll_left = ratchetScrollLeft
			camera.ratchet_scroll_top = ratchetScrollTop
			camera.ratchet_scroll_right = ratchetScrollRight
			camera.ratchet_scroll_bottom = ratchetScrollBottom
