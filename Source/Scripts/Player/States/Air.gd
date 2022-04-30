extends "res://Scripts/Player/State.gd"

var elecPart = preload("res://Entities/Misc/ElecParticles.tscn")

export var isJump = false

# Jump actions
func _input(event):
	if (parent.playerControl != 0):
		# Shield actions
		if (event.is_action_pressed("gm_action") && !parent.abilityUsed && isJump && parent.supTime <= 0):
			parent.abilityUsed = true
			match (parent.shield):
				parent.SHIELDS.NONE:
					if parent.rings >= 50 && !parent.super:
						parent.set_state(parent.STATES.SUPER)
					else:
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


func _physics_process(delta):
	# air movement
	if (parent.inputs[parent.INPUTS.XINPUT] != 0 && parent.airControl):
		
		if (parent.movement.x*parent.inputs[parent.INPUTS.XINPUT] < parent.top):
			if (abs(parent.movement.x) < parent.top):
				parent.movement.x = clamp(parent.movement.x+parent.air/delta*parent.inputs[parent.INPUTS.XINPUT],-parent.top,parent.top)
				
	# Air drag, don't know how accurate this is, may need some tweaking
	if (parent.movement.y < 0 && parent.movement.y > -parent.releaseJmp*60):
		parent.movement.x -= ((parent.movement.x / 0.125) / 256)*60*delta
	
	if (isJump):
		# Cut vertical movement if jump released
		if !parent.inputs[parent.INPUTS.ACTION] && parent.movement.y < -4*60:
				parent.movement.y = -4*60
		# change parent direction
	if (parent.inputs[parent.INPUTS.XINPUT] != 0):
		parent.direction = parent.inputs[parent.INPUTS.XINPUT]
		
	
	# gravity
	parent.movement.y += parent.grv/delta
	
	# reset state if on ground
	if (parent.ground):
		# check bubble shield first
		if parent.bounceReaction != 0:
			parent.movement.y = -parent.bounceReaction*60
			parent.bounceReaction = 0
			if parent.shieldSprite.animation == "BubbleAction" || parent.shieldSprite.animation == "Bubble":
				parent.shieldSprite.play("BubbleBounce")
				parent.sfx[15].play()
				var getTimer = parent.shieldSprite.get_node_or_null("ShieldTimer")
				# Start bubble timer
				if getTimer != null:
					getTimer.start(0.15)
		else:
			parent.set_state(parent.STATES.NORMAL)
	elif parent.movement.y < 0:
		parent.bounceReaction = 0
	
	# set facing direction
	parent.sprite.flip_h = (parent.direction < 0)
	


func _on_ShieldTimer_timeout():
	match(parent.shieldSprite.animation):
		"FireAction":
			parent.shieldSprite.play("Fire")
		"BubbleAction":
			parent.shieldSprite.play("Bubble")
		"BubbleBounce":
			parent.shieldSprite.play("Bubble")
