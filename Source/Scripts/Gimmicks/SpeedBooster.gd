@tool
extends Area2D

@export_enum("left", "right") var boostDirection = 0;
var dirMemory = boostDirection;
var springTextures = [preload("res://Graphics/Gimmicks/springs_yellow.png"),preload("res://Graphics/Gimmicks/springs_red.png")];
var speed = 16;

func _ready():
	$Booster.flip_h = bool(boostDirection)

func _process(delta):
	if Engine.editor_hint:
		if (boostDirection != dirMemory):
			$Booster.flip_h = bool(boostDirection)
			dirMemory = boostDirection;

func _on_SpeedBooster_body_entered(body):
	body.velocity.x = speed*(-1+(boostDirection*2))*Global.originalFPS;
	$sfxSpring.play();
