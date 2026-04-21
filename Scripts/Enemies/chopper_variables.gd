extends Node2D

@export_group("Behavior")

## The height for the Chopper to jump at the first time it comes onscreen. Mashers from Sonic 2 erroniously jump 1 unit lower the first time they load.
@export var first_jump_height: float = 7.0
## The height for the Chopper to jump at after the first time.
@export var jump_height: float = 7.0
## The sprite graphic to use.
@export var sprite_image: Texture2D = preload("res://Graphics/Enemies/chomper.png")
