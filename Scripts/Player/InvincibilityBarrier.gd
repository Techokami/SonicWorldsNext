extends Node2D
## A script for the invincibility barrier that draws stars that spin around the player's position

## The number of stars
const STAR_NUM: int = 8
## An array of values used to offset the rotation angle of the stars for each pair
const STAR_ANGLE_OFFSETS: Array[float] = [0, 118.125, 0, 81.5625]
## The radius of rotation around the player
const STAR_ROTATION_RADIUS: int = 16
## The length of the circular queue used to store the player's position
const POSITION_QUEUE_LENGTH: int = 12
## The region rects of each star frame
const REGIONS: Array[Rect2] = [
	Rect2(0, 0, 31, 31),
	Rect2(31, 0, 31, 31),
	Rect2(62, 0, 31, 31),
	Rect2(93, 0, 31, 31),
	Rect2(124, 0, 31, 31),
	Rect2(155, 0, 31, 31),
	Rect2(186, 0, 31, 31),
	Rect2(217, 0, 31, 31),
]

## An array of arrays that store the frames to cycle through
var star_frame_arr: Array[PackedByteArray] = [
	PackedByteArray([7, 4, 6, 4, 4, 6, 4, 7, 4, 6, 6, 4]),
	PackedByteArray([2, 3, 4, 5, 6, 7, 6, 5, 4, 3]),
	PackedByteArray([1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2]),
	PackedByteArray([0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1]),
]
## A circular queue that stores the player's position
var player_position_queue: PackedVector2Array
## The index of the current position in the queue
var memory_index: int

## An array that stores the coordinates used to position the star pairs and offset them using the circular queue
var star_position_arr: PackedVector2Array
## An array that stores angles used to rotate the stars
## The size of the array determines how many variations of angles that can be stored
var star_angle: Array[float]
## An array that stores frame indices used to animate the stars
## The size of the array determines how many variations of frames that can be stored
var star_frame: Array[int]

## The player that owns this barrier
@onready var player: PlayerChar = get_parent()
## The full spritesheet that has the star frames
@onready var star_spritesheet: Texture2D = preload("res://Graphics/Items/invincible_stars.png")


# Initialize the barrier
func _ready() -> void:
	# Resize some arrays
	player_position_queue.resize(POSITION_QUEUE_LENGTH)
	star_position_arr.resize(ceili(STAR_NUM / 2))
	star_angle.resize(2)
	star_frame.resize(2)


func _physics_process(delta: float) -> void:
	# Don't do anything AT ALL if it ain't visible
	if not visible:
		return
	
	# Increment the frame indices
	star_frame[0] = (star_frame[0] + 1) % 12
	star_frame[1] = (star_frame[1] + 1) % 10
	
	# Store the player's current center position to the queue
	player_position_queue[memory_index] = player.centerReference.global_position
	
	# Increment the memory index so that the stars read from the new index
	memory_index = (memory_index + 1) % POSITION_QUEUE_LENGTH
	
	# Always set the position of the main pair to the player's position
	# If we don't do this and make it read the new positions, instead,
	# the pair will stop for some time before returning to the player, and we don't want that to happen..
	star_position_arr[0] = player.centerReference.global_position
	# Iterate over the array of the star trail positions and set the positions of the star trails
	# to the player's position frames ago and offset them so that the farthest pair from the player
	# is positioned according to the most previous position in the queue
	# (I think the position tracking part needs better descriptions, bruh..)
	for i: int in range(1, star_position_arr.size()):
		var offset_multiplier: int = POSITION_QUEUE_LENGTH / star_position_arr.size()
		star_position_arr[i] = player_position_queue[(memory_index - i * offset_multiplier) % POSITION_QUEUE_LENGTH]
	
	# Increment the angles and rotate based on the player's direction
	star_angle[0] = fmod(star_angle[0] + 101.25 * player.direction * delta * 60, 360) 
	star_angle[1] = fmod(star_angle[1] + 11.25 * player.direction * delta * 60, 360)
	
	# Draw the stars every frame
	queue_redraw()


func _draw() -> void:
	# Iterate over the stars to position and animate em
	# Also, there are local variables that are defined here to keep the code nice and clean,
	# and avoid repeating pieces of code
	# (and also cuz nobody likes scrolling horizontally lol..)
	for star_index in STAR_NUM:
		# The current pair number
		var star_pair_num: int = floori(star_index / 2)
		# Is the index number even or not?
		var is_index_even: bool = star_index % 2 == 0
		# The array that's used to animate the current pair
		var frame_arr: PackedByteArray = star_frame_arr[star_pair_num]
		# The index that points to a variation of a frame
		# Here, it points to the second pair if the index is 1,
		# since it's the one whose stars are animated with the frame array of the least amount of frames,
		# it points to the other pairs if it's zero
		var frame_index: int = int(star_pair_num == 1)
		# The increment of the frame
		# It just increments the frames of the star, whose index is even, by half the amount of frames
		# of the current frame array, eg. If the array has 12 frame numbers,
		# then increase the current frame number by 6
		# Also, the main pair is the exception here, we don't wanna increments the frames of the stars there..
		var frame_increment: int = frame_arr.size() * int(is_index_even and star_index > 0) / 2
		# The index that points to a variation of an angle
		# Here, it points to the main pair if it's 0, and to the trail pair if it's 1,
		# since the main pair should be rotated faster than the trail pairs
		var angle_index: int = int(star_pair_num != 0)
		# The increment of the angle
		# It just increments the star by 180 if its index is even, and offsets the rotation of the star
		# by the angle offset respective to the current pair
		var angle_increment: float = 180 * int(is_index_even) + STAR_ANGLE_OFFSETS[star_pair_num]
		# The rotation of the star
		# It's set to the angle value plus the increment
		# And since we were dealing with the angles in degrees, convert em to radians
		var star_rotation: float = deg_to_rad(star_angle[angle_index] + angle_increment)
		# The position of the star relative to the player
		# It just rotates the star around the center, multiplied by the radius to offset it away
		var star_relative_position: Vector2 = Vector2.from_angle(star_rotation) * STAR_ROTATION_RADIUS
		# Draw the star in set position and region
		draw_texture_rect_region(
			star_spritesheet, # The full spritesheet
			Rect2( # The position and size in a rect
				to_local(star_relative_position + star_position_arr[star_pair_num] - Vector2(16, 16)),
				Vector2(31, 31)),
			REGIONS[frame_arr[(star_frame[frame_index] + frame_increment) % frame_arr.size()]] # The drawn region
		)
