extends Node


# amount of time (in milliseconds) to fade all the other music out (or back in)
# after playing a music theme
const _FADE_SPEED: int = 1*1000

## Level music has the lowest priority, and the Game Over theme has the highest.
enum PriorityLevel {
	LEVEL_THEME,
	EFFECT_THEME,
	BOSS_THEME,
	DROWNING_THEME,
	_1UP_JINGLE,
	STAGE_CLEAR_THEME,
	GAME_OVER_THEME
}

enum _PlayStatus {
	STOPPED,
	PRE_PLAY, # preparing for being played (fading out other music themes that have lower priority)
	PLAYING,
	POST_PLAY # fading out, as well as fading other music themes that have lower priority back in
}

class _MusicThemePlayer extends AudioStreamPlayer:
	var volume_level: float: # we'll use this to accumulate the effect from multiple simultaneous fades
		set(value):
			volume_level = value
			volume_db = linear_to_db(value)
	var play_status: _PlayStatus
	var priority: PriorityLevel
	var fade_out_other_themes: bool # if true, themes with lower priority are faded out gradually,
									# otherwise they're muted immediately
	var fade_in_other_themes: bool # if true, themes with lower priority are faded in gradually,
								   # otherwise they're unmuted immediately
	var fade_when_stopped: bool # if true, theme fades out when stopped via `stop_music_theme()`
	var restart_level_theme: bool # if true, level theme plays from the start
								  # after this music theme stops playing
	var allow_replay: bool
	
	func _init(
		p_stream: AudioStream,
		p_priority: PriorityLevel = PriorityLevel.LEVEL_THEME,
		p_fade_out_other_themes: bool = false,
		p_fade_in_other_themes: bool = false,
		p_fade_when_stopped: bool = false,
		p_restart_level_theme: bool = false,
		p_allow_replay: bool = false
	) -> void:
		bus = &"Music"
		volume_level = 1.0
		play_status = _PlayStatus.STOPPED
		stream = p_stream
		priority = p_priority
		fade_out_other_themes = p_fade_out_other_themes
		fade_in_other_themes = p_fade_in_other_themes
		fade_when_stopped = p_fade_when_stopped
		restart_level_theme = p_restart_level_theme
		allow_replay = p_allow_replay

enum MusicTheme {
	LEVEL_THEME,
	INVINCIBLE,
	SPEED_UP,
	BOSS_THEME,
	STAGE_CLEAR,
	DROWNING,
	_1UP,
	GAME_OVER
}
# TODO: Make this a typed dictionary (Dictionary[MusicTheme, _MusicThemePlayer])
# when transitioning to Godot 4.4
var _music_theme_players: Dictionary = {
	# ID                                                path                                             priority                         fade out others   fade in others   fade when stopped   restart level theme   replay
	MusicTheme.LEVEL_THEME: _create_music_theme(null, PriorityLevel.LEVEL_THEME),
	MusicTheme.INVINCIBLE:  _create_music_theme(preload("res://Audio/Soundtrack/1. SWD_Invincible.ogg"), PriorityLevel.EFFECT_THEME,     false,            false,           false,              true,                 false),
	MusicTheme.SPEED_UP:    _create_music_theme(preload("res://Audio/Soundtrack/2. SWD_SpeedUp.ogg"),    PriorityLevel.EFFECT_THEME,     false,            false,           false,              true,                 false),
	MusicTheme.BOSS_THEME:  _create_music_theme(preload("res://Audio/Soundtrack/5. SWD_Boss.ogg"),       PriorityLevel.BOSS_THEME,       true,             false,           true,               true,                 false),
	MusicTheme.STAGE_CLEAR: _create_music_theme(preload("res://Audio/Soundtrack/4. SWD_StageClear.ogg"), PriorityLevel.STAGE_CLEAR_THEME),
	MusicTheme.DROWNING:    _create_music_theme(preload("res://Audio/Soundtrack/7. SWD_Drowning.ogg"),   PriorityLevel.DROWNING_THEME,   false,            false,           false,              true,                 false),
	MusicTheme._1UP:        _create_music_theme(preload("res://Audio/Soundtrack/3. SWD_1Up.ogg"),        PriorityLevel._1UP_JINGLE,      false,            true,            false,              false,                true),
	MusicTheme.GAME_OVER:   _create_music_theme(preload("res://Audio/Soundtrack/8. SWD_GameOver.ogg"),   PriorityLevel.GAME_OVER_THEME)
}
var _level_theme_alt_player: _MusicThemePlayer = _create_music_theme(null, PriorityLevel.LEVEL_THEME)
var _crossfaded_to_alt: bool = false

# contains the last played music theme of each priority
var _last_played_music_by_priority: Array[_MusicThemePlayer] = []

# signalizes all music playing coroutines to stop
var _reset_music_themes_flag: bool = false


func _fade_music_themes(themes: Array[_MusicThemePlayer], _sign: int) -> void:
	var tree: SceneTree = get_tree()
	var physics_frame: Signal = tree.physics_frame
	var volume_step: float
	var total_volume_change: float = 0.0
	var delta: int
	var prev_time: int
	var cur_time: int = Time.get_ticks_msec()
	var keep_fading: bool = true
	while keep_fading:
		await physics_frame
		prev_time = cur_time
		cur_time = Time.get_ticks_msec()
		# abort if `reset_music_themes()` was called while we're fading out/in
		if _reset_music_themes_flag:
			return
		# skip fading while the game is paused
		if tree.paused:
			continue
		# calculate time passed since the previous frame and total time
		delta = cur_time - prev_time
		# calculate the amount of volume to change at the current step
		volume_step = 1.0 * delta / _FADE_SPEED
		# due to the way how `physics_process` works, the fading process
		# may take slightly more time than specified in `_FADE_SPEED`,
		# which is why we need to compensate for the "overflow"
		# that might happen on the last iteration by clamping
		# the amount of volume changed at the current step
		total_volume_change += volume_step
		if total_volume_change >= 1.0:
			keep_fading = false # this will be the last iteration
			volume_step -= total_volume_change - 1.0 # compensate for the "overflow"
		volume_step *= _sign
		# change the voulme for all specified themes
		for theme: _MusicThemePlayer in themes:
			theme.volume_level += volume_step


## Plays the specified music theme while muting out (either instantly,
## or by gradually fading out) all the other themes that have lower priority,
## then fading them back in after the specified theme ended playing.[br]
## * [param theme_id] - music theme to play.[br]
## * [param time] - time (in milliseconds) to play the [param theme], if the latter is looped.[br]
## NOTES:[br]
## * If [code]theme_id == MusicTheme.LEVEL[/code] and level theme wasn't previously
##   set (which can be done either via the `level_music_theme` property in
##   the editor, or via [member set_level_music]), this function does nothing.
func play_music_theme(theme_id: MusicTheme) -> void:
	var theme: _MusicThemePlayer = _music_theme_players[theme_id]

	# if it's a level theme and wasn't previously set via `set_level_music()`,
	# or if the theme is already playing and re-playing is not allowed,
	# then we have a quick exit
	if (theme_id == MusicTheme.LEVEL_THEME and theme.stream == null or
		theme.playing and not theme.allow_replay):
		return
	
	var priority: PriorityLevel = theme.priority
	var prev_theme: _MusicThemePlayer = _last_played_music_by_priority[priority]
	_last_played_music_by_priority[priority] = theme # replace the last played music of this priority
	if prev_theme != null and prev_theme.play_status == _PlayStatus.PRE_PLAY:
		# we are already preparing another music theme with the same priority
		# for being played (fading out all music with lower priority), so all
		# we need to do is to replace the last played music of the same priority
		# (which we just did; see the above comment) and reset the play status
		# of the previous music theme if we aren't re-playing the same theme -
		# and then we can have a quick exit
		if prev_theme != theme:
			prev_theme.play_status = _PlayStatus.STOPPED
		return
	
	# pick other music themes with lower priority, so we can fade them out
	var other_themes: Array[_MusicThemePlayer] = []
	for other_theme_id: MusicTheme in _music_theme_players:
		var other_theme: _MusicThemePlayer = _music_theme_players[other_theme_id]
		if other_theme.priority < priority:
			other_themes.append(other_theme)
	
	if prev_theme != null and prev_theme.play_status == _PlayStatus.PLAYING:
		# this can be one of the following sitiations:
		# a) music theme with the same priority is already being played and we're replacing it,
		# b) we're re-playing the same music theme
		# in either of those cases we don't need to fade out other music
		pass
	elif not theme.fade_out_other_themes:
		# if there's no fadeout, then we can simply mute
		# all the other music that has lower priority
		for other_theme: _MusicThemePlayer in other_themes:
			other_theme.volume_level -= 1.0
	else:
		# otherwise we need to gradually fade out
		# all the other music themes with lower priority
		theme.play_status = _PlayStatus.PRE_PLAY
		await _fade_music_themes(other_themes, -1)
		# abort if `reset_music_themes()` was called
		if _reset_music_themes_flag:
			return
	
	# the theme might have been replaced by another call of `play_music_theme()`
	# while we were fading out all the other music
	theme = _last_played_music_by_priority[priority]
	
	# only play the music if it wasn't stopped via `stop_music_theme()`
	# while we were fading out all the other music (if the music was stopped,
	# then we can skip playing it and proceed to fading all the other music back in)
	if theme.play_status != _PlayStatus.POST_PLAY:
		# stop the previous theme and play the current one
		if prev_theme != null and (prev_theme.play_status == _PlayStatus.PLAYING or prev_theme.play_status == _PlayStatus.PRE_PLAY):
			prev_theme.stop()
			prev_theme.play_status = _PlayStatus.STOPPED
		theme.play()
		if theme_id == MusicTheme.LEVEL_THEME:
			_level_theme_alt_player.play()
		theme.play_status = _PlayStatus.PLAYING
		
		# wait for the theme to finish playing
		var tree: SceneTree = get_tree()
		var physics_frame: Signal = tree.physics_frame
		while (theme.playing or tree.paused) and theme.play_status == _PlayStatus.PLAYING:
			await physics_frame
			# abort if `reset_music_themes()` was called
			if _reset_music_themes_flag:
				return
	
		# if the theme was stopped via `stop_music_theme()` (`POST_PLAY` status),
		# we need to fade out the theme
		if theme.fade_when_stopped and theme.play_status == _PlayStatus.POST_PLAY:
			if theme_id == MusicTheme.LEVEL_THEME:
				_fade_music_themes([_level_theme_alt_player], -1)
			await _fade_music_themes([theme], -1)
			# abort if `reset_music_themes()` was called
			if _reset_music_themes_flag:
				return
			# stop the theme and restore its volume
			theme.stop()
			theme.volume_level += 1.0
			if theme_id == MusicTheme.LEVEL_THEME:
				_level_theme_alt_player.stop()
				_level_theme_alt_player.volume_level += 1.0

	# remove the current theme from the list of last played themes
	_last_played_music_by_priority[priority] = null
	
	# fade all the other music back in
	if not theme.fade_in_other_themes:
		for other_theme: _MusicThemePlayer in other_themes:
			other_theme.volume_level += 1.0
	else:
		theme.play_status = _PlayStatus.POST_PLAY
		await _fade_music_themes(other_themes, 1)
		# abort if `reset_music_themes()` was called
		if _reset_music_themes_flag:
			return
	
	# restart the level theme, if needed
	if theme.restart_level_theme:
		seek_music_theme(MusicTheme.LEVEL_THEME, 0.0)
	
	# finally, set the `STOPPED` status, and we're done
	theme.play_status = _PlayStatus.STOPPED

## Stops the specified music theme.[br]
## [param theme_id] - music theme to stop.[br]
## NOTES:[br]
## * If [code]theme_id == MusicTheme.LEVEL[/code] and level theme wasn't previously
## set via [member set_level_music] or set to [code]null[/code], this function does nothing.
func stop_music_theme(theme_id: MusicTheme) -> void:
	var theme: _MusicThemePlayer = _music_theme_players[theme_id]
	if theme_id == MusicTheme.LEVEL_THEME and theme.stream == null:
		return
	
	# if the theme was in `PRE_PLAY` or `PLAYING` stage, change it to `POST_PLAY`,
	# so that the corresponding `play_music_theme()` coroutine would know
	# that it can skip playing the theme
	if theme.play_status != _PlayStatus.STOPPED:
		theme.play_status = _PlayStatus.POST_PLAY
	
	# only stop the theme if it's not supposed to be faded when stopped
	# (if it's supposed to be faded, the stopping is done by the corresponding
	# `play_music_theme()` coroutine)
	if not theme.fade_when_stopped:
		theme.stop()
		if theme_id == MusicTheme.LEVEL_THEME:
			_level_theme_alt_player.stop()

## Restarts the specified music theme from position.
## Does nothing if music theme isn't played.
func seek_music_theme(theme_id: MusicTheme, to_position: float) -> void:
	_music_theme_players[theme_id].seek(to_position)
	if theme_id == MusicTheme.LEVEL_THEME:
		_level_theme_alt_player.seek(to_position)

## Returns [code]true[/code] if the specified music theme is playing, [code]false[/code] otherwise.
func is_music_theme_playing(theme_id: MusicTheme) -> bool:
	return _music_theme_players[theme_id].play_status == _PlayStatus.PLAYING

## Returns [code]true[/code] if the specified music theme is playing,
## preparing to play (fading out other music themes with lower priority),
## or just finished playing and now all the other themes with lower priority
## are fading back in. Returns [code]false[/code] otherwise.
func is_music_theme_playing_or_fading(theme_id: MusicTheme) -> bool:
	return _music_theme_players[theme_id].play_status != _PlayStatus.STOPPED

## Returns [code]true[/code] if any music theme with the specified priority is playing,
## [code]false[/code] otherwise.
func is_music_theme_with_priority_playing(priority: PriorityLevel) -> bool:
	var theme: _MusicThemePlayer = _last_played_music_by_priority[priority]
	return theme != null and theme.play_status == _PlayStatus.PLAYING

## Returns [code]true[/code] if any music theme with the specified priority is playing,
## preparing to play (fading out other music themes with lower priority),
## or just finished playing and now all the other themes with lower priority
## are fading back in. Returns [code]false[/code] otherwise.
func is_music_theme_with_priority_playing_or_fading(priority: PriorityLevel) -> bool:
	var theme: _MusicThemePlayer = _last_played_music_by_priority[priority]
	return theme != null and theme.play_status != _PlayStatus.STOPPED

## Stops any music theme with the specified priority.
func stop_music_theme_with_priority(priority: PriorityLevel) -> void:
	var theme: _MusicThemePlayer = _last_played_music_by_priority[priority]
	if theme == null:
		return
	var theme_id = _music_theme_players.find_key(theme)
	assert(theme_id is MusicTheme)
	stop_music_theme(theme_id)

## Stops all currently playing music themes.
func stop_all_music_themes() -> void:
	for theme_id: MusicTheme in _music_theme_players:
		stop_music_theme(theme_id)

## Returns the position the music is played at, or [code]0.0[/code] if music isn't playing.
func get_music_theme_playback_position(theme_id: MusicTheme) -> float:
	var theme: _MusicThemePlayer = _music_theme_players[theme_id]
	if not theme.playing:
		return 0.0
	return theme.get_playback_position() + AudioServer.get_time_since_last_mix()

## Sets music theme for the current level.[br]
## [param music] - music to set as a level theme.[br]
## [param music_alt] - alternative music stream (for crossfading with [param music]).[br]
## [param autoplay] - if [code]true[/code], start playing the music immediately.
func set_level_music(music: AudioStream, music_alt: AudioStream = null, autoplay: bool = true) -> void:
	_music_theme_players[MusicTheme.LEVEL_THEME].stop()
	_level_theme_alt_player.stop()
	_music_theme_players[MusicTheme.LEVEL_THEME].stream = music
	_level_theme_alt_player.stream = music_alt
	if autoplay:
		play_music_theme(MusicTheme.LEVEL_THEME)

## Crossfade level music from the primary theme to the alternative one or vice-versa.
## [param to_alt] - if [code]true[/code], crossfading goes from primary to alternative, otherwise vice-versa.
func crossfade_level_music(to_alt: bool) -> void:
	var level_theme: _MusicThemePlayer = _music_theme_players[MusicTheme.LEVEL_THEME]
	# quit if we already crossfaded in this direction
	if to_alt == _crossfaded_to_alt:
		return
	_crossfaded_to_alt = to_alt
	_fade_music_themes([level_theme], -1 if to_alt else 1)
	_fade_music_themes([_level_theme_alt_player], 1 if to_alt else -1)

## Resets all music.
func reset_music_themes() -> void:
	var theme: _MusicThemePlayer
	for theme_id: MusicTheme in _music_theme_players:
		theme = _music_theme_players[theme_id]
		theme.stop()
		theme.play_status = _PlayStatus.STOPPED
		theme.volume_level = 1.0
	_level_theme_alt_player.stop()
	_level_theme_alt_player.volume_level = 0.0
	_crossfaded_to_alt = false
	_last_played_music_by_priority.fill(null)
	_reset_music_themes_flag = true

func _create_music_theme(
	stream: AudioStream,
	priority: PriorityLevel = PriorityLevel.LEVEL_THEME,
	fade_out_other_themes: bool = false,
	fade_in_other_themes: bool = false,
	fade_when_stopped: bool = false,
	restart_level_theme: bool = false,
	allow_replay: bool = false
) -> _MusicThemePlayer:
	var theme: _MusicThemePlayer = _MusicThemePlayer.new(
		stream, priority, fade_out_other_themes, fade_in_other_themes,
		fade_when_stopped, restart_level_theme, allow_replay)
	add_child(theme)
	return theme

func _ready() -> void:
	assert(MusicTheme.values() == _music_theme_players.keys())
	
	# add an extra slot for the alternative level theme so `play_music_theme()`
	# will be able to automatically fade it in/out when needed
	_music_theme_players[-1] = _level_theme_alt_player
	
	_music_theme_players.make_read_only()
	_last_played_music_by_priority.resize(PriorityLevel.size())
	_level_theme_alt_player.volume_level = 0.0 # the alt level theme is silent by default

func _physics_process(_delta: float) -> void:
	# music playing coroutines update before this flag is set
	# to false, as they await for `get_tree().physics_frame`
	# which fires before `_physics_process()` is called
	_reset_music_themes_flag = false
