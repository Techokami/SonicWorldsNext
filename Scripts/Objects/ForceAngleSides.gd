@tool
extends Area2D

@export_range(-90,90) var leftAngle = 0.0 # (float, -90, 90)
@export_range(-90,90) var rightAngle = 0.0 # (float, -90, 90)
@export var stickUntilExit = true

@export var maxAngleDifference = 15.0 # (float, -90, 90)
@export var speedRange = 2
var dropOff = 24

var players = []
var contactPoint = []

func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()

func _physics_process(_delta):
	if players.size() > 0:
		contactPoint.resize(players.size())
		for i in players:
			var getIndex = players.find(i)
			if i.ground and contactPoint[getIndex] != null and abs(i.movement.x) >= speedRange*60:
				var PrevAngle = i.angle
				
				if contactPoint[getIndex] < 0:
					if leftAngle != null:
						i.angle = -deg_to_rad(leftAngle)
				else:
					if rightAngle != null:
						i.angle = deg_to_rad(rightAngle)
				
				# if greater then angle difference and distance from center is below drop off, disconect from floor
				if abs(i.angle-PrevAngle) >= deg_to_rad(maxAngleDifference) and abs(i.global_position.x-global_position.x) < dropOff:
					i.disconect_from_floor()
			else:
				# set contact point to player floor sensor position
				var getVert = i.get_nearest_vertical_sensor()
				if getVert != null:
					contactPoint[getIndex] = getVert.get_collision_point().x - global_position.x
				else:
					contactPoint[getIndex] = null
			
			

func _draw():
	if Engine.is_editor_hint():
		# Left Arrow
		if leftAngle != null:
			draw_line(Vector2.ZERO,Vector2(-32,0).rotated(deg_to_rad(-leftAngle)),Color(0,1,1,0.5),1.5)
		# Right Arrow
		if rightAngle != null:
			draw_line(Vector2.ZERO,Vector2(32,0).rotated(deg_to_rad(rightAngle)),Color(0,1,1,0.5),1.5)


func _on_ForceAngleSides_body_entered(body):
	if !players.has(body):
		players.append(body)
		contactPoint.resize(players.size())
		# set contact point to player floor sensor position
		var getVert = body.get_nearest_vertical_sensor()
		if getVert != null:
			contactPoint[players.size()-1] = getVert.get_collision_point().x - global_position.x
		else:
			contactPoint[players.size()-1] = null


func _on_ForceAngleSides_body_exited(body):
	if players.has(body):
		# remove angle rotation index
		var getIndex = players.find(body)
		contactPoint.remove_at(getIndex)
		
		players.erase(body)
