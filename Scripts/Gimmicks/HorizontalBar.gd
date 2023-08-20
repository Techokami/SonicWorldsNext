@tool
extends Node2D

# Mushroom Hill Zone Horizontal Bars
# Author: DimensionWarped

# A little info about how your textures should be arranged:
# The spritesheet needs to be vertically divisible by 3. The width can be
# whatever you like, but the Main_Body portion needs to stretch across the
# entirety of the bar and the texture *should* be imported to repeat. If you
# don't repeat the texture, it will repeat the last column over and over instead
# of repeating the whole width of the body texture.
# The individual parts of the texture should be vertically aligned to link up
# with one another. In the included texture, this means the MainBody is set one
# pixel below the top line.
@export var spriteTexture = load("res://Graphics/Gimmicks/HorizontalBar.png")

# How wide the left anchor is in the sprite in pixels -- specify this if you don't want the drawing
# to have gaps in it.
@export var leftAnchorWidth = 6

# How wide the right anchor is in the sprite in pixels -- specify this if you don't want the drawing
# to have gaps in it.
@export var rightAnchorWidth = 6

# how wide is this bar? Change my size in the editor and I will auto-update!
# NOTE: If you change other parameters, such as the sprite texture or whether or
# not to draw the left/right anchors, you need to modify this value to make it
# update. You can put it back afterwards if you need to.
@export var width = 64

# allow brake - If this parameter is toggled on, players may hold against
# the direction of travel to stop themselves.
@export var allowBrake = false

# How many pixels per second do you want to allow the player to move side to
# side while riding -- affects both the shimmy and the swinging parts of the
# gimmick
@export var shimmySpeed = 60.0 # one pixel per frame at 60fps

# Allows side to side movement on the gimmick for both shimmy and the normal bar
# swing
@export var allowShimmy = true

# Allows the player to cancel the swing by jumping
@export var allowJumpOff = true

# If this is true, the player may hold down when jumping to dismount from the
# gimmick downwards (only applies to shimmy mode) - otherwise the player can
# only jump upwards (which usually means re-entering the gimmick in swing mode)
@export var allowDownwardDetach = false

# If this is false, don't draw the left anchor. The body size will be adjusted accordingly.
@export var drawLeftAnchor = true
# If this is false, don't draw the right anchor. The body size will be adjusted accordingly.
@export var drawRightAnchor = true

# How fast the player must be moving (upwards or downwards) when hitting the
# gimmick to enter the swing animation... usually this is rather low. If this
# value is not met when allowShimmy is on, the player will enter shimmy mode
# instead. If this value is not met and allowShimmy is false, then the player
# will simply bypass the gimmick. In the original implementation, a player meets
# this requirement by falling for more than 32 pixels... or 13 frames of gravity
# accumulating as Y Velocity
@export var swingContactSpeed = 80.0

# This value is only used to resize the gimmick in tool mode
var previousWidth = width

# array of players currently interacting with the gimmick
var players = []

# Called when the node enters the scene tree for the first time.
func _ready():
	# This value is only used to know when to update the size in tool mode
	previousWidth = width
	resize()
	
func resize():
	print("resize")
	var bodyWidth = width
	if drawLeftAnchor:
		bodyWidth -= leftAnchorWidth
	if drawRightAnchor:
		bodyWidth -= rightAnchorWidth
	
	$Main_Body.set_region_rect(Rect2(0, 0, bodyWidth, spriteTexture.get_height() / 3))
	
	$Left_Anchor.visible = drawLeftAnchor
	$Right_Anchor.visible = drawRightAnchor
	
	if not drawLeftAnchor:
		$Main_Body.position.x = 0
	else:
		$Main_Body.position.x = leftAnchorWidth
		
	$Right_Anchor.position.x = leftAnchorWidth + bodyWidth if drawLeftAnchor else bodyWidth

	$Main_Body.set_texture(spriteTexture)
	$Left_Anchor.set_texture(spriteTexture)
	$Left_Anchor.set_region_rect(Rect2(0, spriteTexture.get_height() / 3, leftAnchorWidth, spriteTexture.get_height() / 3))
	$Right_Anchor.set_texture(spriteTexture)
	$Right_Anchor.set_region_rect(Rect2(0, spriteTexture.get_height() / 3 * 2, rightAnchorWidth, spriteTexture.get_height() / 3))
	
	var shape = RectangleShape2D.new()
	var collision = $Bar_Area/CollisionShape2D
	shape.size.y = 4
	shape.size.x = width
	
	collision.set_shape(shape)
	if (width % 2 == 0):
		collision.position = Vector2(width / 2, 3)
	else:
		collision.position = Vector2(((width) / 2) + 0.5, 3)
	pass
	
func process_tool():
	if previousWidth != width:
		resize()
		previousWidth = width
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#if Engine.is_editor_hint():
	process_tool()
