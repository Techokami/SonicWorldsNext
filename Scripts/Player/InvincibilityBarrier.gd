extends Node2D
## A script for the invincibility barrier that draws stars that spin around and trail behind the player's position.


## The number of stars.
const STAR_NUM: int = 8
## This array stores the increments to each angle variant in [member star_angles].
const ANGLE_INCREMENTS: Array[float] = [101.25, 11.25]
## An array of values used to offset the rotation angle of the stars for each pair.
const ANGLE_OFFSETS: Array[float] = [0.0, 118.125, 0.0, 81.5625]
## The radius of rotation of stars around the player.
const ROTATION_RADIUS: float = 16.0
## The length of the circular queue used to store the player's position.
const POSITION_QUEUE_LENGTH: int = 12
## This array stores the unique sizes of arrays in the [member star_frame_arr] array.
## Here, for example, all arrays in [member star_frame_arr] currently contain 12 elements except
## one which contains 10, so this array stores the sizes of 12 and 10
const FRAME_ARR_SIZES: Array[int] = [12, 10]
## The region rects of each star frame.
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
## The full spritesheet that has the star frames.
const StarSpritesheet: Texture2D = preload("res://Graphics/Items/invincible_stars.png")

## An array of arrays that store the frames to cycle through.
var star_frame_arr: Array[PackedByteArray] = [
	PackedByteArray([7, 4, 6, 4, 4, 6, 4, 7, 4, 6, 6, 4]),
	PackedByteArray([2, 3, 4, 5, 6, 7, 6, 5, 4, 3]),
	PackedByteArray([1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2]),
	PackedByteArray([0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1]),
]
## A circular queue that stores the player's position.
var player_position_queue: PackedVector2Array
## The index of the current position in the queue.
var memory_index: int

## An array that stores the coordinates used to position the star pairs and offset them using the circular queue.
var star_position_arr: PackedVector2Array
## An array that stores angles used to rotate the stars.
## The size of the array determines how many variations of angles that can be stored.
var star_angles: Array[float]
## An array that stores frame indices used to animate the stars.
## The size of the array determines how many variations of frames that can be stored.
var star_frames: Array[int]

## The player that owns this barrier.
@onready var player: PlayerChar = get_parent()


# Initialize the barrier.
func _ready() -> void:
	# Resize some arrays.
	player_position_queue.resize(POSITION_QUEUE_LENGTH)
	star_position_arr.resize(ceili(STAR_NUM / 2))
	star_frames.resize(FRAME_ARR_SIZES.size())
	star_angles.resize(ANGLE_INCREMENTS.size())


# Run some calculations used to draw the stars later, aka positions, angles and frames.
func _physics_process(delta: float) -> void:
	# Store the player's current center position to the queue.
	player_position_queue[memory_index] = player.centerReference.global_position
	
	# Increment the memory index so that the stars read from the new index.
	memory_index = (memory_index + 1) % POSITION_QUEUE_LENGTH
	
	# Always set the position of the main pair to the player's position.
	# If we don't do this and make it read the new positions, instead,
	# the pair will stop for some time before returning to the player, and we don't want that to happen..
	star_position_arr[0] = player.centerReference.global_position
	# Store the size of the position array.
	var position_arr_size: int = star_position_arr.size()
	# Also store the multiplier that's used to offset the trail pairs.
	var offset_multiplier: int = POSITION_QUEUE_LENGTH / position_arr_size
	# Iterate over the array of the star trail positions and set the positions of the star trails
	# to the player's position frames ago and offset them so that the farthest pair from the player
	# is positioned according to the most previous position in the queue.
	# (I think the position tracking part needs better descriptions, bruh..)
	for i: int in range(1, position_arr_size):
		star_position_arr[i] = player_position_queue[(memory_index - i * offset_multiplier) % POSITION_QUEUE_LENGTH]
	
	# Only do certain stuff if the barrier is visible..
	if visible:
		# Increment the frame indices.
		for i: int in star_frames.size():
			star_frames[i] = (star_frames[i] + 1) % FRAME_ARR_SIZES[i]
		
		# Store the direction multiplier.
		# (Idk if this name fits since it also stores the delta time multiplied
		# by 60 fps to accomodate for different refresh rates..)
		var direction_multiplier: float = player.get_direction_multiplier() * delta * 60.0
		# Increment the angles and rotate based on the player's direction.
		for i: int in star_angles.size():
			star_angles[i] = fmod(star_angles[i] + ANGLE_INCREMENTS[i] * direction_multiplier, 360.0)
		
		# Draw the stars every frame.
		queue_redraw()


# Draws the stars manually.
func _draw() -> void:
	# Iterate over the stars to position and animate em.
	# Also, there are local variables that are defined here to keep the code nice and clean,
	# and avoid repeating pieces of code. (And also cuz nobody likes scrolling horizontally lol..)
	for star_index: int in STAR_NUM:
		# The current pair number.
		# It divides the current star index by 2 and then Godot automatically truncates the result to the nearest
		# integer if the result is a decimal due to the index being an odd number.
		var star_pair_num: int = star_index / 2
		# Is the index number even or not?
		var is_index_even: bool = star_index % 2 == 0
		# The array that's used to animate the current pair.
		var frame_arr: PackedByteArray = star_frame_arr[star_pair_num]
		# The size of the current frame array.
		var frame_size: int = frame_arr.size()
		# The index that points to a variation of a frame.
		# Here, it points to the second pair if the index is 1,
		# since it's the one whose stars are animated with the frame array of the least amount of frames,
		# it points to the other pairs if it's zero.
		var frame_index: int = int(star_pair_num == 1)
		# The increment of the frame.
		# It just increments the frames of the star, whose index is even, by half the amount of frames
		# of the current frame array, eg. If the array has 12 frame numbers,
		# then increase the current frame number by 6.
		# Also, the main pair is the exception here, we don't wanna increments the frames of the stars there..
		var frame_increment: int = frame_size * int(is_index_even and star_index > 0) / 2
		# The region rect of the star frame that should be drawn.
		var star_frame_region: Rect2 = \
				REGIONS[frame_arr[(star_frames[frame_index] + frame_increment) % frame_size]]
		# The size of the region rect of the current frame.
		var region_rect_size: Vector2 = star_frame_region.size
		# The index that points to a variation of an angle.
		# Here, it points to the main pair if it's 0, and to the trail pair if it's 1,
		# since the main pair should be rotated faster than the trail pairs.
		var angle_index: int = int(star_pair_num != 0)
		# The increment of the angle.
		# It just increments the star by 180 if its index is even, and offsets the rotation of the star
		# by the angle offset respective to the current pair.
		var angle_offset: float = 180.0 * float(is_index_even) + ANGLE_OFFSETS[star_pair_num]
		# The rotation of the star.
		# It's set to the angle value plus the increment.
		# And since we were dealing with the angles in degrees, convert em to radians..
		var star_rotation: float = deg_to_rad(star_angles[angle_index] + angle_offset)
		# The position of the star relative to the player.
		# It just rotates the star around the center, multiplied by the radius to offset it away with a set radius.
		var star_relative_position: Vector2 = Vector2.from_angle(star_rotation) * ROTATION_RADIUS
		# The final position of the star.
		# It's set to the relative position combined with the current stored position of the current star pair
		# relative to the player (since the draw methods here draw stuff in local space) and offsets it by the
		# size of the region rect (because the draw methods here draw stuff in the top left of the parent..)
		var star_final_position: Vector2 = \
				star_relative_position + to_local(star_position_arr[star_pair_num]) - region_rect_size.ceil() / 2
		# Draw the star in set position and region.
		# Also sorry for the long wall of local variables and comments but those variables are necessary.
		# (Not sure if describing what each variable does is necessary or nah..)
		draw_texture_rect_region(
			StarSpritesheet, # The full spritesheet.
			Rect2( # The position and size in a rect.
				star_final_position,
				region_rect_size
			),
			star_frame_region # The region rect of the drawn frame.
		)
