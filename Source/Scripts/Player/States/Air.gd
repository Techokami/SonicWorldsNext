extends "res://Scripts/Player/State.gd"

var elecPart = preload("res://Entities/Misc/ElecParticles.tscn")

export var isJump = false

# drop dash variables
var dropSpeed = [8,12] #the base speed for a drop dash, second is super
var dropMax = [12,13]   #the top speed for a drop dash, second is super
var dropTimer = 0

# Jump actions
func _process(delta):
	if parent.playerControl != 0 or (parent.inputs[parent.INPUTS.YINPUT] < 0 and parent.character == parent.CHARACTERS.TAILS):
		# Super
		if parent.inputs[parent.INPUTS.SUPER] == 1 and !parent.super and isJump:
			if parent.rings >= 50:
				parent.set_state(parent.STATES.SUPER)
		# Shield actions
		if (parent.inputs[parent.INPUTS.ACTION] == 1 and !parent.abilityUsed and isJump):
			# Super actions
			if parent.super and parent.character == parent.CHARACTERS.SONIC:
				parent.abilityUsed = true # has to be set to true for drop dash (Sonic only)
			# Normal actions
			else:
				match (parent.character):
					parent.CHARACTERS.SONIC:
						parent.abilityUsed = true
						match (parent.shield):
							parent.SHIELDS.NONE:
								parent.sfx[16].play()
								parent.shieldSprite.play("Insta")
								parent.shieldSprite.frame = 0
								parent.shieldSprite.visible = true
								parent.shieldSprite.get_node("InstaShieldHitbox/HitBox").disabled = false
								yield(parent.shieldSprite,"animation_finished")
								# check shields hasn't changed
								if (parent.shield == parent.SHIELDS.NONE):
									parent.shieldSprite.visible = false
									parent.shieldSprite.stop()
								parent.shieldSprite.get_node("InstaShieldHitbox/HitBox").disabled = true
							
							parent.SHIELDS.ELEC:
								parent.sfx[13].play()
								parent.movement.y = -5.5*Global.originalFPS
								for i in range(4):
									var part = elecPart.instance()
									part.global_position = parent.global_position
									part.direction = Vector2(1,1).rotated(deg2rad(90*i))
									parent.get_parent().add_child(part)
							
							parent.SHIELDS.FIRE:
								parent.sfx[14].play()
								parent.movement = Vector2(8*Global.originalFPS*parent.direction,0)
								parent.shieldSprite.play("FireAction")
								var getTimer = parent.shieldSprite.get_node_or_null("ShieldTimer")
								# Start fire dash timer
								if getTimer != null:
									getTimer.start(0.5)
								parent.shieldSprite.flip_h = (parent.direction < 0)
								parent.lock_camera(16.0/60.0)
							
							parent.SHIELDS.BUBBLE:
								# check animation isn't bouncing
								if parent.shieldSprite.animation != "BubbleBounce":
									parent.sfx[15].play()
									parent.movement = Vector2(0,8*Global.originalFPS)
									parent.bounceReaction = 7.5
									parent.shieldSprite.play("BubbleAction")
									var getTimer = parent.shieldSprite.get_node_or_null("ShieldTimer")
									# Start bubble timer
									if getTimer != null:
										getTimer.start(0.25)
								else:
									parent.abilityUsed = false
					parent.CHARACTERS.TAILS:
						parent.set_state(parent.STATES.FLY)


func _physics_process(delta):
	# air movement
	if (parent.inputs[parent.INPUTS.XINPUT] != 0 and parent.airControl):
		
		if (parent.movement.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (abs(parent.movement.x) < parent.top):
				parent.movement.x = clamp(parent.movement.x+parent.air/delta*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top)
				
	# Air drag
	if (parent.movement.y < 0 and parent.movement.y > -parent.releaseJmp*60):
		parent.movement.x -= ((parent.movement.x / 0.125) / 256)*60*delta
	
	# Mechanics if jumping
	if (isJump):
		# Cut vertical movement if jump released
		if !parent.inputs[parent.INPUTS.ACTION] and parent.movement.y < -4*60:
			parent.movement.y = -4*60
		# Drop dash (for sonic)
		if parent.character == parent.CHARACTERS.SONIC:
			
			if parent.inputs[parent.INPUTS.ACTION] and parent.abilityUsed and (parent.shield <= parent.SHIELDS.NORMAL or parent.super):
				if dropTimer < 1:
					dropTimer += (delta/20)*60 # should be ready in the equivelent of 20 frames at 60FPS
				else:
					if parent.animator.current_animation != "dropDash":
						parent.sfx[20].play()
						parent.animator.play("dropDash")
			# Drop dash reset
			elif !parent.inputs[parent.INPUTS.ACTION] and dropTimer > 0:
				dropTimer = 0
				if parent.animator.current_animation == "dropDash":
					parent.animator.play("roll")
	
		
	# Change parent direction
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		parent.direction = parent.inputs[parent.INPUTS.XINPUT]
	
	# set facing direction
	parent.sprite.flip_h = (parent.direction < 0)
	
	# Gravity
	parent.movement.y += parent.grv/delta
	
	# Reset state if on ground
	if (parent.ground):
		# Check bounce reaction first
		if parent.bounceReaction != 0:
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
		else:
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
					parent.movement.x = clamp((parent.movement.x/4) + (dropSpeed[int(parent.super)]*60*parent.direction), -dropMax[int(parent.super)]*60,dropMax[int(parent.super)]*60)
				# Backwards landing
				else:
					# if floor angle is flat then just set to drop speed
					if is_equal_approx(parent.angle,parent.gravityAngle):
						parent.movement.x = dropSpeed[int(parent.super)]*60*parent.direction
					# else calculate landing
					else:
						parent.movement.x = clamp((parent.movement.x/2) + (dropSpeed[int(parent.super)]*60*parent.direction), -dropMax[int(parent.super)]*60,dropMax[int(parent.super)]*60)
				# stop vertical movement downard
				parent.movement.y = min(0,parent.movement.y)
				parent.set_state(parent.STATES.ROLL)
				parent.animator.play("roll")
				parent.sfx[20].stop()
				parent.sfx[3].play()
				# Lag camera
				parent.lock_camera(16.0/60.0)
				
				# drop dash dust
				var dust = parent.Particle.instance()
				dust.play("DropDash")
				dust.global_position = parent.global_position
				dust.scale.x = parent.direction
				parent.get_parent().add_child(dust)
					
	elif parent.movement.y < 0:
		parent.bounceReaction = 0
	
	


func _on_ShieldTimer_timeout():
	match(parent.shieldSprite.animation):
		"FireAction":
			parent.shieldSprite.play("Fire")
		"BubbleAction":
			parent.shieldSprite.play("Bubble")
		"BubbleBounce":
			parent.shieldSprite.play("Bubble")

func state_activated():
	dropTimer = 0
	
func state_exit():
	# deactivate insta shield
	if (parent.shield == parent.SHIELDS.NONE):
		parent.shieldSprite.visible = false
		parent.shieldSprite.stop()
	parent.shieldSprite.get_node("InstaShieldHitbox/HitBox").disabled = true
	parent.enemyCounter = 0
