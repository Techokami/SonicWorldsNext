extends PlayerState

var elecPart = preload("res://Entities/Misc/ElecParticles.tscn")

@export var isJump = false

var lockDir = false


func _ready():
	super()
	if isJump: # we only want to connect it once so only apply this to the jump variation
		parent.connect("enemy_bounced",Callable(self,"bounce"))


# reset drop dash timer and gripping when this state is set
func state_activated():
	parent.poleGrabID = null
	# disable water run splash
	parent.action_water_run_handle()


func state_process(_delta: float) -> void:
	if parent.playerControl != 0 or (parent.inputs[parent.INPUTS.YINPUT] < 0 and parent.character == Global.CHARACTERS.TAILS):
		# Super
		if parent.inputs[parent.INPUTS.SUPER] == 1 and !parent.isSuper and isJump:
			# Global emeralds use a bit flag, Global.EMERALDS.ALL would mean all 7 are 1, see bitwise operations for more info
			if parent.rings >= 50 and Global.emeralds >= Global.EMERALDS.ALL:
				parent.set_state(parent.STATES.SUPER)


func state_physics_process(delta: float) -> void:
	# air movement
	if (parent.inputs[parent.INPUTS.XINPUT] != 0 and parent.airControl):
		
		if (parent.movement.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (abs(parent.movement.x) < parent.top):
				parent.movement.x = clamp(parent.movement.x+parent.air/GlobalFunctions.div_by_delta(delta)*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top)
				
	# Air drag
	if (parent.movement.y < 0 and parent.movement.y > -parent.releaseJmp*60):
		parent.movement.x -= ((parent.movement.x / 0.125) / 256)*60*delta
	
	# Mechanics if jumping
	if (isJump):
		# Cut vertical movement if jump released
		if !parent.any_action_held_or_pressed() and parent.movement.y < -parent.releaseJmp*60:
			parent.movement.y = -parent.releaseJmp*60
		
	# Change parent direction
	# Check that lock direction isn't on
	if !lockDir and parent.inputs[parent.INPUTS.XINPUT] != 0:
			parent.direction = parent.inputs[parent.INPUTS.XINPUT]
	
	# set facing direction
	parent.sprite.flip_h = (parent.direction < 0)
	
	# Gravity
	parent.movement.y += parent.grv/GlobalFunctions.div_by_delta(delta)
	
	# Reset state if on ground
	if (parent.ground):
		#Restore Air Control when landing
		#(Needed if Rolling control lock is enabled in Roll.gd)
		parent.airControl = true
		# Check bounce reaction first (this kinda feels like character specific code, but maybe not)
		if !bounce():
			# reset animations (this is for shared animations like the corkscrews)
			parent.animator.play("RESET")
			# return to normal state
			parent.set_state(parent.STATES.NORMAL)
		else:
			parent.emit_player_bounce()
	
	# if velocity going up reset bounce reaction
	elif parent.movement.y < 0:
		parent.bounceReaction = 0


func state_exit():
	if parent.ground:
		parent.movement.y = min(parent.movement.y,0)
	parent.poleGrabID = null
	parent.enemyCounter = 0
	lockDir = false


# bounce handling
func bounce():
	# check if bounce reaction is set
	if parent.bounceReaction != 0:
		# set bounce movement
		parent.movement.y = -parent.bounceReaction*60
		parent.bounceReaction = 0
		parent.abilityUsed = false
		return true
	# if no bounce then return false to continue with landing routine
	return false
