## Extends Camera2D by providing functionality the standard Camera2D doesn't have,
## such as camera lock time, look offset when looking up/down, etc.
class_name PlayerCamera extends Camera2D

# The player this camera is attached to.
var player: PlayerChar

## Rect (measured in pixels) located at the center of viewport, whithin which the player can move
## without the camera moving to follow them.
var dist: Vector2 = Vector2(32.0,64.0)

## Max. camera offset by the Y axis when looking up/down.[br]
## [code]look_dist[0][/code] is up, [code]look_dist[1][/code] is down.
var look_dist: Array[float] = [-104.0,88.0]

## Camera movement speed when the player is looking up/down.
var look_amount: float = 0.0

## Camera offset when the player is looking up/down.
var look_offset: float = 0.0

var adjust: Vector2 = Vector2.ZERO

## Multiplier for [code]dist.y[/code].[br]
## See also: [member dist].
var drag_lerp: float = 0.0

## Time remaining until the camera scrolling is unlocked.
var lock_time: float = 0.0

var target_limit_left: float = 0   ## Left boundary.
var target_limit_right: float = 0  ## Left boundary.
var target_limit_top: float = 0    ## Top boundary.
var target_limit_bottom: float = 0 ## Bottom boundary.

var ratchet_scroll_left: bool = false   ## Prevents the camera from scrolling to the left.
var ratchet_scroll_right: bool = false  ## Prevents the camera from scrolling to the right.
var ratchet_scroll_top: bool = false    ## Prevents the camera from scrolling upwards.
var ratchet_scroll_bottom: bool = false ## Prevents the camera from scrolling downwards.

func _init(p_player: PlayerChar) -> void:
	player = p_player
	player.get_parent().call_deferred(&"add_child",self)
	
	enabled = (player.playerControl == 1)
	var view_size: Vector2 = player.get_viewport_rect().size
	drag_left_margin =   dist.x/view_size.x
	drag_right_margin =  dist.x/view_size.x
	drag_top_margin =    dist.y/view_size.y
	drag_bottom_margin = dist.y/view_size.y
	drag_horizontal_enabled = true
	drag_vertical_enabled = true
	player.connect(&"positionChanged",Callable(self,&"update").bind(true))
	global_position = player.global_position
	
	# await for the 1'st frame before reading the boundaries
	(func() -> void:
		target_limit_left = Global.hardBorderLeft
		target_limit_right = Global.hardBorderRight
		target_limit_top = Global.hardBorderTop
		target_limit_bottom = Global.hardBorderBottom
		limit_left = int(target_limit_left)
		limit_right = int(target_limit_right)
		limit_top = int(target_limit_top)
		limit_bottom = int(target_limit_bottom)
	).call_deferred()

## Locks the position of the camera for a while.[br]
## [param time] - how long (in seconds) to lock the camera for.[br]
## [b]Note:[/b] If the camera is already locked, this function can raise
## the locked time up to [param time], but it can't go below the current
## remaining lock time.
func lock(time: float = 1.0):
	lock_time = maxf(time,lock_time)

## Repositions the player camera per normal camera movement rules
## [param force_move] - ignores camera locking mechanics if [code]true[/code].
func update(force_move: bool = false) -> void:
	var player_state: PlayerChar.STATES = player.get_state()
	
	# Cancel camera movement
	if player_state == PlayerChar.STATES.DIE:
		return
	
	# Camera vertical drag
	var view_size: Vector2 = player.get_viewport_rect().size
	
	drag_top_margin =    lerpf(0.0,dist.y/view_size.y,drag_lerp)
	drag_bottom_margin = drag_top_margin
	
	# Extra drag margin for rolling
	adjust = Vector2.ZERO
	match player.character:
		Global.CHARACTERS.TAILS:
			if player_state == PlayerChar.STATES.ROLL:
				adjust = Vector2(0.0,-1.0)
		_: # default
			if player_state == PlayerChar.STATES.ROLL:
				adjust = Vector2(0.0,-5.0)
	
	# Camera lock
	# remove round() if you are not making a pixel perfect game
	var look_pos: Vector2 = (player.global_position+Vector2(0,look_offset)+adjust).round()
	if lock_time == 0.0 and (force_move or global_position.distance_to(look_pos) <= 16.0):
		# limit_length speed camera
		var delta: float = 16.0*60.0*get_physics_process_delta_time()
		global_position.x = move_toward(global_position.x,look_pos.x,delta)
		global_position.y = move_toward(global_position.y,look_pos.y,delta)
		# clamp to region
		global_position.x = clampf(global_position.x,target_limit_left,target_limit_right)
		global_position.y = clampf(global_position.y,target_limit_top,target_limit_bottom)
		#global_position = global_position.move_toward(look_pos,16.0*60.0*get_physics_process_delta_time())
		# uncomment below for immediate camera
		#global_position = look_pos
	
	# Ratchet camera scrolling (locks the camera behind the player)
	if ratchet_scroll_left:
		target_limit_left = maxf(target_limit_left,get_screen_center_position().x-view_size.x/2.0)
	if ratchet_scroll_right:
		target_limit_right = maxf(target_limit_right,get_screen_center_position().x+view_size.x/2.0)
	
	if ratchet_scroll_top:
		target_limit_top = maxf(target_limit_top,get_screen_center_position().y-view_size.y/2.0)
	if ratchet_scroll_bottom:
		target_limit_bottom = maxf(target_limit_bottom,get_screen_center_position().y+view_size.y/2.0)

func finalize(delta: float) -> void:
	# Lerp camera scroll based on if on floor
	var player_offset: float = (absf(player.global_position.y-get_target_position().y)*2.0)/dist.y
	var scroll_speed: float = 4.0*60.0*delta
	
	drag_lerp = maxf(float(!player.ground),minf(drag_lerp,player_offset)-6.0*delta)
	
	# Looking/Lag
	look_amount = clampf(look_amount,-1.0,1.0)
	look_offset = lerpf(0.0,look_dist[0],minf(0.0,-look_amount))+lerpf(0.0,look_dist[1],minf(0.0,look_amount))
	
	if look_amount != 0.0:
		var look_direction: float = signf(look_amount)
		var tmp_scroll_speed: float = look_direction*delta*2.0
		if signf(look_amount-tmp_scroll_speed) == look_direction:
			look_amount -= look_direction*delta*2.0
		else:
			look_amount = 0.0
	
	# Camera Lock
	if lock_time != 0.0:
		lock_time = maxf(0.0,lock_time-delta)
	
	# Boundry handling
	# Pan camera limits to boundries
	var view_size: Vector2 = player.get_viewport_rect().size
	var view_pos: Vector2 = get_screen_center_position()
	
	# Left
	# snap the limit to the edge of the camera if snap out of range
	if target_limit_left > view_pos.x-view_size.x*0.5:
		limit_left = maxi(int(view_pos.x-view_size.x*0.5),limit_left)
	# if limit is inside the camera then pan over
	if absf(limit_left-(view_pos.x-view_size.x*0.5)) <= view_size.x*0.5:
		limit_left = int(move_toward(limit_left,target_limit_left,scroll_speed))
	# else just snap the camera limit since it's not going to move the camera
	else:
		limit_left = int(target_limit_left)
	
	# Right
	# snap the limit to the edge of the camera if snap out of range
	if target_limit_right < view_pos.x+view_size.x*0.5:
		limit_right = mini(int(view_pos.x+view_size.x*0.5),limit_right)
	# if limit is inside the camera then pan over
	if absf(limit_right-(view_pos.x+view_size.x*0.5)) <= view_size.x*0.5:
		limit_right = int(move_toward(limit_right,target_limit_right,scroll_speed))
	# else just snap the camera limit since it's not going to move the camera
	else:
		limit_right = int(target_limit_right)

	# Top
	# snap the limit to the edge of the camera if snap out of range
	if target_limit_top > view_pos.y-view_size.y*0.5:
		limit_top = maxi(int(view_pos.y-view_size.y*0.5),limit_top)
	# if limit is inside the camera then pan over
	if absf(limit_top-(view_pos.y-view_size.y*0.5)) <= view_size.y*0.5:
		limit_top = int(move_toward(limit_top,target_limit_top,scroll_speed))
	# else just snap the camera limit since it's not going to move the camera
	else:
		limit_top = int(target_limit_top)
	
	# Bottom
	# snap the limit to the edge of the camera if snap out of range
	if target_limit_bottom < view_pos.y+view_size.y*0.5:
		limit_bottom = mini(int(view_pos.y+view_size.y*0.5),limit_bottom)
	# if limit is inside the camera then pan over
	if absf(limit_bottom-(view_pos.y+view_size.y*0.5)) <= view_size.y*0.5:
		limit_bottom = int(move_toward(limit_bottom,target_limit_bottom,scroll_speed))
	# else just snap the camera limit since it's not going to move the camera
	else:
		limit_bottom = int(target_limit_bottom)
