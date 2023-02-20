extends Node2D
tool

# Tool for adding waterfalls (and possibly other things that act like waterfalls) to a scene.
# Basically a tool for adding tilable animated graphics.

# How many units
export var width = 4 # How many units wide the water fall is (32x pixels each)

# How many units tall the body of the waterfall is. Note that the top of the
# waterfall is an additional item that rests on top of this one.
# 1 unit is 16 pixels of added height, 0 = 16px tall total (just the top of the waterfall)
# 9 = 160px tall (16 * 9 for the base, +16 more for the top
export var height = 4

# Set this to false to disable drawing of the top of the waterfall
export var drawTop = true

# How much time in seconds passes between frames
export var framePeriod = 0.125

# Body uses an array of textures - one texture per frame of animation. Has to be that way since
# we rely on texture wrapping in both directions.
export(Array, Texture) var bodyTextures

# The top texture uses a single texture for all animation frames. We can do that because it only
# needs to tile left to right, so we can just grow the texture downwards to add more frames.
export(Texture) var topTexture

# How many frames are in the animation for the top sprite -- make sure this is right for your texture
# or the top sprite will draw incorrectly.
export var topFrames = 4

# These are just used by the tool functions to track whether or not something has changed
var lastWidth = width
var lastHeight = height
var lastDrawTop = drawTop

# Used to track which frame the waterfall animation is currently on
var curFrame = 0
var lastUpdateTime = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	lastWidth = width
	lastHeight = height
	lastDrawTop = drawTop
	pass # Replace with function body.
	
	$WaterfallTop.set_region_rect(Rect2(0, 0, topTexture.get_width() * width, topTexture.get_height() / topFrames))
	$WaterfallBody.set_region_rect(Rect2(0, 0, topTexture.get_width() * width, bodyTextures[0].get_height() * height))
	
func process_editor(_delta):
	if width != lastWidth or lastDrawTop != drawTop or lastHeight != height:
		# Come back here and make it use the properties of the sprite
		# Also add a frames variable
		
		if (!drawTop):
			$WaterfallTop.visible = false
		else:
			$WaterfallTop.visible = true

		# Note that the top texture sets its animation frame by adjusting the y starting position of the regionRect.
		# That's why it is able to animate with just one texture -- the body of the waterfall has to be able to tile
		# in both directions, so that trick won't work there.
		$WaterfallTop.set_region_rect(Rect2(0, 0, topTexture.get_width() * width, topTexture.get_height() / topFrames))
		$WaterfallBody.set_region_rect(Rect2(0, 0, topTexture.get_width() * width, bodyTextures[0].get_height() * height))
			
		# Reset our tracking variables
		lastWidth = width
		lastDrawTop = drawTop
		lastHeight = height
	pass
	
func advance_frame_top():
	$WaterfallTop.set_region_rect(Rect2(0, curFrame * topTexture.get_height() / topFrames, topTexture.get_width() * width, topTexture.get_height() / topFrames))
	
func advance_frame_body():
	$WaterfallBody.set_texture(bodyTextures[curFrame % bodyTextures.size()])
	
func _process(delta):
	if Engine.is_editor_hint():
		process_editor(delta)

	var curTime = Time.get_ticks_msec() / 1000.0
	
	# No need to do anything yet if we haven't reached the frame advancement time
	if curTime - lastUpdateTime < framePeriod:
		return
		
	curFrame += 1

	lastUpdateTime = curTime
	# Do animation -- this step happens regardless of whether we are in editor or in game.

	if drawTop:
		advance_frame_top()
		
	advance_frame_body()
