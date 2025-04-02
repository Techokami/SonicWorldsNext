extends AudioStreamPlayer2D

## Provides very basic controls for audiostreams which for some reason aren't
## Accessible to signals from the outset. Just bind this script to StreamPlayer
## And you'll be able to control it with signals!

## A value that is used when picking a pitch with do_play_w_pitch
## Usually a value between .1 and .2 is best, but you can pick any float.
@export var rand_pitch_range : float = 0.0

## Sets the pitch that the play functions use as the central pitch.
@export var main_pitch : float = 1.0

## Make stream play. Usable from a signal.
## _junk_arg is provided as a way of calling this from a singal that has one argument
## effectively making it so that you can call this via s signal with either 0 or 1 args.
func do_play(_junk_arg=null):
	self.pitch_scale = main_pitch
	self.play()

## Plays the stream with the randomized pitch from rand_pitch_range used.
## Does not persist the change in pitch.
func do_play_random_pitch(_junk_arg=null):
	self.pitch_scale = randf_range(self.main_pitch - rand_pitch_range,
								   self.main_pitch + rand_pitch_range)
	self.play()

## Make stream stop playing. Usable from a signal.
## _junk_arg is provided as a way of calling this from a signal that has one argument.
## effectively making it so that you can call this via a signal with either 0 or 1 args.
func do_stop(_junk_arg=null):
	self.stop()

## Set stream volume. Usable form a signal.
func do_set_volume(new_volume):
	self.set_volume_db(new_volume)

## Sets the main pitch value.
func set_main_pitch(new_pitch):
	self.main_pitch = new_pitch

## Sets the maximum variability in the random pitch
func set_random_pitch_range(max_diff : float):
	self.rand_pitch_range = max_diff
