tool
extends Node2D

# The texture to draw your animated rings from - frames must be arranged horizontally and spaced evenly
export var spriteTexture = preload("res://Graphics/Gimmicks/ICZTrampolineRingAnim.png")

# The total number of frames in your texture animation
export var spriteFrameCount = 17

# How to animate the rings
# pingpong - the animation will bounce back and forth from start to finish
# loop - the animation will go from start to finish and then start over
enum ANIMATION_MODE {pingpong, loop}
export(ANIMATION_MODE) var animationMode = ANIMATION_MODE.pingpong

# How long each frame of animation should last in seconds
export var time_per_frame = 0.10

# how far into the current animation we are in time
var _anim_timer = 0.0
# current frame to draw... sort of (may be negative)
var _cur_frame = 0
# current frame to draw, really (absolute value of cur_frame in case of pingpong)
var frameToDraw = 0
# tracks how wide the sprite frame is.
var spriteFrameWidth
# tracks how tall the sprite frame is.
var spriteFrameHeight

var drawAtPosQueue = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_anim_timer = 0
	spriteFrameWidth = spriteTexture.get_width() / spriteFrameCount
	spriteFrameHeight = spriteTexture.get_height()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		if (spriteFrameWidth == null or spriteFrameHeight == null):
			_ready()

	_anim_timer += delta
	if _anim_timer > time_per_frame:
		_cur_frame += 1
		_anim_timer -= time_per_frame
		if _cur_frame == spriteFrameCount:
			if animationMode == ANIMATION_MODE.pingpong:
				_cur_frame = -spriteFrameCount + 1
			elif animationMode == ANIMATION_MODE.loop:
				_cur_frame = 0

	frameToDraw = abs(_cur_frame)
	update()
	
func draw_at_pos(pos):
	drawAtPosQueue.append(pos)
	
func draw_at_pos_internal(pos):
	if Engine.is_editor_hint():
		if (spriteFrameWidth == null or spriteFrameHeight == null):
			_ready()
			
	draw_texture_rect_region(spriteTexture,
			Rect2(Vector2(-0.5 * spriteFrameWidth, -0.5 * spriteFrameHeight) + pos, Vector2(spriteFrameWidth, spriteFrameHeight)),
			Rect2(Vector2(spriteFrameWidth * frameToDraw, 0), Vector2(spriteFrameWidth, spriteFrameHeight)))
	pass
	
func draw_at_pos_for_real():
	for pos in drawAtPosQueue:
		draw_texture_rect_region(spriteTexture,
				Rect2(Vector2(-0.5 * spriteFrameWidth, -0.5 * spriteFrameHeight) + pos, Vector2(spriteFrameWidth, spriteFrameHeight)),
				Rect2(Vector2(spriteFrameWidth * frameToDraw, 0), Vector2(spriteFrameWidth, spriteFrameHeight)))
		pass
		
	drawAtPosQueue.clear()
		
func _draw():
	draw_at_pos_for_real()
