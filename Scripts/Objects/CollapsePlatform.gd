extends Area2D

@export_node_path("TileMap")var tile
@export var speed = 3.0

var players = []
var active = false

# tile list array, contains an array inside set up like this
# [time left, cell coordinant]
var getTiles = []

func _ready():
	tile = get_node(tile)
	# grab from first layer
	for i in tile.get_used_cells(0):
		# calculate by distance and give co-ordinant
		getTiles.append([i.length()/speed,i])

func _physics_process(delta):
	if !active:
		for i in players:
			if i.ground:
				active = true
	else:
		for i in getTiles.size():
			# check that i is still below the tile size
			if i < getTiles.size():
				# decrease timer
				if getTiles[i][0] > 0:
					getTiles[i][0] -= delta
				# remove timer (and array point)
				else:
					# erase from tilemap
					tile.set_cell(0,getTiles[i][1])
					getTiles.remove_at(i)
					# decrease so we don't skip
					i -= 1


func _on_body_entered(body):
	if !players.has(body):
		players.append(body)

func _on_body_exited(body):
	if players.has(body):
		players.erase(body)
