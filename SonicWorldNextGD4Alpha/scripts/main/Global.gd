extends Node
var globalSound = [preload("res://Audio/SFX/Objects/RingStereo.wav")]
var soundPlayer = AudioStreamPlayer.new()
enum SOUNDS {RING}

var main = null

func _ready():
	add_child(soundPlayer)

func play_sound(sound = SOUNDS.RING):
	soundPlayer.stream = globalSound[sound]
	soundPlayer.play()
