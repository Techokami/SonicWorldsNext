## Provides mechanisms for controlling player layers via signals rather than
## Just using the layer switcher objects.

extends Node


func move_player_high(player):
	player.collissionLayer = Global.LAYERS.HIGH

func move_player_low(player):
	player.collissionLayer = Global.LAYERS.LOW

func switch_player(player):
	if player.collisionLayer == Global.LAYERS.LOW:
		player.collisionLayer = Global.LAYERS.HIGH
		return
	player.collisionLayer = Global.Layers.LOW
