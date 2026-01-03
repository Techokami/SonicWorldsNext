extends PlayerState

var elecPart = preload("res://Entities/Misc/ElecParticles.tscn")
var lockDir = false
var avatar: ShadowAvatar

#Stomp Attack is basically a stripped down air state with no bounce and no x movement control.

func _ready():
	super()
	parent.connect("enemy_bounced",Callable(self,"bounce"))

# reset drop dash timer and gripping when this state is set
func state_activated():
	parent.poleGrabID = null
	# disable water run splash
	parent.action_water_run_handle()
	avatar = parent.get_avatar()

func state_process(_delta: float) -> void:
	pass

func state_physics_process(delta: float) -> void:
	var physics = parent.get_physics()
	var top_speed = physics.top_speed
	var air_accel = physics.air_acceleration
	var release_jump = physics.release_jump

	# air movement
	# Stomp attack does not care about x input, x speed is always zero'd.
	parent.movement.x = 0
				
	# Air drag
	if (parent.movement.y < 0 and parent.movement.y > -release_jump * 60):
		parent.movement.x -= ((parent.movement.x / 0.125) / 256)*60*delta
	
	
	# Gravity
	parent.movement.y += parent.get_physics().gravity / GlobalFunctions.div_by_delta(delta)
	
	# If movement reverses for some reason, switch back to normal air state -- bounce *should* be
	# disabled, but it's possible something else might force us back upwards.
	if parent.movement.y < 0:
		parent.set_state(parent.STATES.AIR)
		
	
	# Reset state if on ground -- also needs some effects to be played
	if (parent.ground):
		#Restore Air Control when landing
		#(Needed if Rolling control lock is enabled in Roll.gd)
		parent.airControl = true
		avatar.sfx[1].play() # plays Shadow's stomp landing sound
		parent.set_state(parent.STATES.NORMAL)


func state_exit():
	var shadow_avatar: ShadowAvatar = parent.get_avatar()
	if parent.ground:
		parent.movement.y = min(parent.movement.y,0)
	parent.enemyCounter = 0
	shadow_avatar.vfx_animator.play("RESET")
	lockDir = false


# bounce handling
func bounce():
	var shadow_avatar: ShadowAvatar = parent.get_avatar()
	print("enemy bounce")
	# check if bounce reaction is set
	if parent.bounceReaction != 0:
		# set bounce movement
		parent.movement.y = -parent.bounceReaction*60
		parent.bounceReaction = 0
		shadow_avatar.shadow_reset_abilities(null, -1, null, -1)
		return true
	# if no bounce then return false to continue with landing routine
	return false
