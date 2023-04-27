extends PlayerState

var elecPart = preload("res://Entities/Misc/ElecParticles.tscn")

@export var isJump = false

# drop dash variables
var dropSpeed = [8,12] #the base speed for a drop dash, second is super
var dropMax = [12,13]   #the top speed for a drop dash, second is super
var dropTimer = 0

var lockDir = false

func _ready():
	if isJump: # we only want to connect it once so only apply this to the jump variation
		parent.connect("enemy_bounced",Callable(self,"bounce"))

# Jump actions
func _process(_delta):
	if parent.playerControl != 0 or (parent.inputs[parent.INPUTS.YINPUT] < 0 and parent.character == parent.CHARACTERS.TAILS):
		# Super
		if parent.inputs[parent.INPUTS.ACTION3] == 1 and !parent.isSuper and isJump:
			# Global emeralds use a bit flag, 127 would mean all 7 are 1, see bitwise operations for more info
			if parent.rings >= 50 and Global.emeralds >= 127:
				parent.set_state(parent.STATES.SUPER)
		# Shield actions
		elif ((parent.inputs[parent.INPUTS.ACTION] == 1 or parent.inputs[parent.INPUTS.ACTION2] == 1 or parent.inputs[parent.INPUTS.ACTION3] == 1) and !parent.abilityUsed and isJump):
			# Super actions
			if parent.isSuper and parent.character == parent.CHARACTERS.SONIC:
				parent.abilityUsed = true # has to be set to true for drop dash (Sonic only)
			# Normal actions
			else:
				match (parent.character):
					parent.CHARACTERS.SONIC:
						# set ability used to true to prevent multiple uses
						parent.abilityUsed = true
						# check that the invincibility barrier isn't visible
						if !$"../../InvincibilityBarrier".visible:
							match (parent.shield):
								# insta shield
								parent.SHIELDS.NONE:
									parent.sfx[16].play()
									parent.shieldSprite.play("Insta")
									parent.shieldSprite.frame = 0
									parent.shieldSprite.visible = true
									# enable insta shield hitbox
									parent.shieldSprite.get_node("InstaShieldHitbox/HitBox").disabled = false
									# wait for animation for the shield to finish
									await parent.shieldSprite.animation_finished
									# check shields hasn't changed
									if (parent.shield == parent.SHIELDS.NONE):
										parent.shieldSprite.visible = false
										parent.shieldSprite.stop()
									# disable insta shield
									parent.shieldSprite.get_node("InstaShieldHitbox/HitBox").disabled = true
								
								# elec shield action
								parent.SHIELDS.ELEC:
									parent.sfx[13].play()
									# set movement upwards
									parent.movement.y = -5.5*60.0
									# generate 4 electric particles and send them out diagonally (rotated for each iteration of i to 4)
									for i in range(4):
										var part = elecPart.instantiate()
										part.global_position = parent.global_position
										part.direction = Vector2(1,1).rotated(deg_to_rad(90*i))
										parent.get_parent().add_child(part)
								
								# fire shield action
								parent.SHIELDS.FIRE:
									# partner check (so you don't flame boost when you're trying to fly with tails
									if !(parent.inputs[parent.INPUTS.YINPUT] < 0 and parent.partner != null):
										parent.sfx[14].play()
										parent.movement = Vector2(8*60*parent.direction,0)
										parent.shieldSprite.play("FireAction")
										# set timer for animation related resets
										var getTimer = parent.shieldSprite.get_node_or_null("ShieldTimer")
										# Start fire dash timer
										if getTimer != null:
											getTimer.start(0.5)
										# change orientation to match the movement
										parent.shieldSprite.flip_h = (parent.direction < 0)
										# lock camera for a short time
										parent.lock_camera(16.0/60.0)
								
								# bubble shield actions
								parent.SHIELDS.BUBBLE:
									# check animation isn't already bouncing
									if parent.shieldSprite.animation != "BubbleBounce":
										parent.sfx[15].play()
										# set movement and bounce reaction
										parent.movement = Vector2(0,8*60)
										parent.bounceReaction = 7.5
										parent.shieldSprite.play("BubbleAction")
										# set timer for animation related resets
										var getTimer = parent.shieldSprite.get_node_or_null("ShieldTimer")
										# Start bubble timer
										if getTimer != null:
											getTimer.start(0.25)
									else:
										parent.abilityUsed = false
					# Tails flight
					parent.CHARACTERS.TAILS:
						parent.set_state(parent.STATES.FLY)
					# Knuckles gliding
					parent.CHARACTERS.KNUCKLES:
						# set initial movement
						parent.movement = Vector2(parent.direction*4*60,max(parent.movement.y,0))
						parent.set_state(parent.STATES.GLIDE,parent.currentHitbox.GLIDE)


func _physics_process(delta):
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
		if !(parent.inputs[parent.INPUTS.ACTION] or parent.inputs[parent.INPUTS.ACTION2] or parent.inputs[parent.INPUTS.ACTION3]) and parent.movement.y < -4*60:
			parent.movement.y = -4*60
		# Drop dash (for sonic)
		if parent.character == parent.CHARACTERS.SONIC:
			
			if (parent.inputs[parent.INPUTS.ACTION] or parent.inputs[parent.INPUTS.ACTION2] or parent.inputs[parent.INPUTS.ACTION3]) and parent.abilityUsed and (parent.shield <= parent.SHIELDS.NORMAL or parent.isSuper or $"../../InvincibilityBarrier".visible):
				if dropTimer < 1:
					dropTimer += (delta/20)*60 # should be ready in the equivelent of 20 frames at 60FPS
				else:
					if parent.animator.current_animation != "dropDash":
						parent.sfx[20].play()
						parent.animator.play("dropDash")
			# Drop dash reset
			elif !(parent.inputs[parent.INPUTS.ACTION] or parent.inputs[parent.INPUTS.ACTION2] or parent.inputs[parent.INPUTS.ACTION3]) and dropTimer > 0:
				dropTimer = 0
				if parent.animator.current_animation == "dropDash":
					parent.animator.play("roll")
	
		
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
		# Check bounce reaction first
		if !bounce():
			# reset animations (this is for shared animations like the corkscrews)
			parent.animator.play("RESET")
			# return to normal state
			parent.set_state(parent.STATES.NORMAL)
			
			# Drop dash release (for sonic)
			if dropTimer >= 1 and parent.character == parent.CHARACTERS.SONIC:
				# Check if moving forward or back
				# Forward landing
				if sign(parent.movement.x) == sign(parent.direction) or parent.movement.x == 0:
					# Calculate landing and limit to top speed
					parent.movement.x = clamp((parent.movement.x/4) + (dropSpeed[int(parent.isSuper)]*60*parent.direction), -dropMax[int(parent.isSuper)]*60,dropMax[int(parent.isSuper)]*60)
				# Backwards landing
				else:
					# if floor angle is flat then just set to drop speed
					if is_equal_approx(parent.angle,parent.gravityAngle):
						parent.movement.x = dropSpeed[int(parent.isSuper)]*60*parent.direction
					# else calculate landing
					else:
						parent.movement.x = clamp((parent.movement.x/2) + (dropSpeed[int(parent.isSuper)]*60*parent.direction), -dropMax[int(parent.isSuper)]*60,dropMax[int(parent.isSuper)]*60)
				# stop vertical movement downard
				parent.movement.y = min(0,parent.movement.y)
				parent.set_state(parent.STATES.ROLL)
				parent.animator.play("roll")
				parent.sfx[20].stop()
				parent.sfx[3].play()
				# Lag camera
				parent.lock_camera(16.0/60.0)
				
				# drop dash dust
				var dust = parent.Particle.instantiate()
				dust.play("DropDash")
				dust.global_position = parent.global_position+Vector2(0,2).rotated(parent.rotation)
				dust.scale.x = parent.direction
				parent.get_parent().add_child(dust)
	# if velocity going up reset bounce reaction
	elif parent.movement.y < 0:
		parent.bounceReaction = 0
	
	

# Shield timer timeouts (used to reset animations)
func _on_ShieldTimer_timeout():
	match(parent.shieldSprite.animation):
		"FireAction":
			parent.shieldSprite.play("Fire")
		"BubbleAction":
			parent.shieldSprite.play("Bubble")
		"BubbleBounce":
			parent.shieldSprite.play("Bubble")

# reset drop dash timer and gripping when this state is set
func state_activated():
	dropTimer = 0
	parent.poleGrabID = null
	
func state_exit():
	# deactivate insta shield
	if (parent.shield == parent.SHIELDS.NONE):
		parent.shieldSprite.visible = false
		parent.shieldSprite.stop()
	parent.poleGrabID = null
	parent.shieldSprite.get_node("InstaShieldHitbox/HitBox").set_deferred("disabled",true)
	parent.enemyCounter = 0
	lockDir = false

# bounce handling
func bounce():
	# check if bounce reaction is set
	if parent.bounceReaction != 0:
		# set bounce movement
		parent.movement.y = -parent.bounceReaction*60
		parent.bounceReaction = 0
		# bubble shield actions
		if parent.shieldSprite.animation == "BubbleAction" or parent.shieldSprite.animation == "Bubble":
			parent.shieldSprite.play("BubbleBounce")
			parent.sfx[15].play()
			var getTimer = parent.shieldSprite.get_node_or_null("ShieldTimer")
			# Start bubble timer
			if getTimer != null:
				getTimer.start(0.15)
		parent.abilityUsed = false
		return true
	# if no bounce then return false to continue with landing routine
	return false
