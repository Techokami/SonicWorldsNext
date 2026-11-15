## Provides mechanisms for controlling player layers via signals rather than
## Just using the layer switcher objects.

extends Node


func move_player_high(player):
	player.collision_plane = Global.COLLISION_PLANES.HIGH

func move_player_low(player):
	player.collision_plane = Global.COLLISION_PLANES.LOW

func switch_player(player):
	if player.collision_plane == Global.COLLISION_PLANES.LOW:
		player.collision_plane = Global.COLLISION_PLANES.HIGH
		return
	player.collision_plane = Global.COLLISION_PLANES.LOW
