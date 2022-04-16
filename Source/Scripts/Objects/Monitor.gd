tool
extends KinematicBody2D

var physics = false;
var grv = 0.21875;
var yspeed = 0;
var playerTouch = null;
export (int, "Ring", "Speed Shoes", "Invincibility", "Shield", "Elec Shield", "Fire Shield",
"Bubble Shield", "Super", "Blue Ring", "Boost", "1up") var item = 0;


func _ready():
	$Item.frame = item+2

func _process(delta):
	if (Engine.is_editor_hint()):
		$Item.frame = item+2

func destroy():
	$Item.z_index += 1000
	$Animator.play("DestroyMonitor")
	$SFX/Destroy.play()
	yield($Animator,"animation_finished")
	# enable effect
	match (item):
		0: # Rings
			playerTouch.rings += 10
			$SFX/Ring.play()
		1: # Speed Shoes
			playerTouch.shoeTime = 30
			playerTouch.switch_physics(3)
			Global.music.stream_paused = true
			Global.currentTheme = 1
			Global.effectTheme.stream = Global.themes[Global.currentTheme]
			Global.effectTheme.play()
		2: # Invincibility
			playerTouch.supTime = 30
			playerTouch.shieldSprite.visible = false
			playerTouch.get_node("InvincibilityBarrier").visible = true
			Global.music.stream_paused = true
			Global.currentTheme = 0
			Global.effectTheme.stream = Global.themes[Global.currentTheme]
			Global.effectTheme.play()
		3: # Shield
			playerTouch.set_shield(playerTouch.SHIELDS.NORMAL)
		4: # Elec
			playerTouch.set_shield(playerTouch.SHIELDS.ELEC)
		5: # Fire
			playerTouch.set_shield(playerTouch.SHIELDS.FIRE)
		6: # Bubble
			playerTouch.set_shield(playerTouch.SHIELDS.BUBBLE)
		7: # Super
			playerTouch.switch_physics(4)
			playerTouch.supTime = 3000
			playerTouch.shoeTime = playerTouch.supTime
			playerTouch.rings += 50
			playerTouch.shieldSprite.visible = false
			Global.music.stream_paused = true
			Global.currentTheme = 0
			Global.effectTheme.stream = Global.themes[Global.currentTheme]
			Global.effectTheme.play()

func _physics_process(delta):
	if (!Engine.is_editor_hint()):
		if (physics):
			var collide = move_and_collide(Vector2(0,yspeed)*delta)
			yspeed += grv/delta
			if (collide && yspeed > 0):
				physics = false

func physics_collision(body, hitVector):
	if (body.animator.current_animation == "roll"):
		if hitVector.y < 0:
			body.movement.y *= -1
			yspeed = -1.5*60
			physics = true
		elif hitVector.x != 0:
			playerTouch = body
			destroy()
		else:
			body.movement.y *= -1
			body.ground = false
			playerTouch = body
			destroy()
	return true;
