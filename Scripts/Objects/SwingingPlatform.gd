# Swinging code contributed by ChrisFurry

@tool # A tool you can use in the editor!!
extends Node2D # Change this and it probably breaks

# Export Variables
@export var chains:int = 8 # How many chains will be rendered # (int,0,100)
@export var chain_size:int = 16 # The size of the chains (should be the same width and height, can be easily changed though if you want a different width and height)
@export var speed = 1.0 # Speed of the movement, but the heigher it is the slower it goes, and the lower it is (greater than 0) the faster it goes # (float,0,5)
@export var dir = 1 # The direction of the swing's movement # (int,-1,1)
@export var rotate_amount = 90.0 # How far do you want the swings to rotate? # (float,1.0,180.0)
@export var plat_img:Texture2D # Texture2D for hte platform
@export var chain_img:Texture2D # Texture2D for the chains
# Declare time, previous position, editor time, and grab the platform's node
var time = 0
var edittime = 0 # Time for the editor version
@onready var platform = $SwingBase # Grab the platform's node.


# Called when the node enters the scene tree for the first time.
func _ready():
	if(!Engine.is_editor_hint()): # If not in editor, show the platform, and set the platform's image
		platform.show()
		platform.get_node("Sprite2D").texture = plat_img
		# Change platform shape
		platform.get_node("Shape3D").shape.size.x = plat_img.get_size().x
	else: # Hide platform from editor
		platform.hide() # The platform is drawn in this script instead for the editor.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(Engine.is_editor_hint()): # All the editor code is in draw
		edittime = fmod(edittime + (delta * 60 * speed) * dir,360)
	# Update is used in editor, and for the chains on the swing.
	queue_redraw()

func _physics_process(_delta):
	if(!Engine.is_editor_hint()): # Do all of the platform code if not in the editor
		# Calculate direction for the platform
		var direction = Vector2.DOWN.rotated(-deg_to_rad(sin(deg_to_rad(fmod(Global.globalTimer * 60 * speed * dir,360))) * rotate_amount))
		# Calculate the position of the platform, using the variable we got from the chains.
		var distance = chains * chain_size + (float(chain_size) / 2.0)
		platform.position = (direction * distance).round()
		

func _draw():
	var temppos
	if(!Engine.is_editor_hint()):  # Non-editor stuff
		# Calcutlate direction
		var direction = platform.position.normalized()
		# Draw Each Chain
		for i in chains:
			# Calculate Position
			temppos = direction * ((i + 1) * chain_size)
			# Center chain
			temppos -= Vector2(float(chain_img.get_width()) / 2,float(chain_img.get_height()) / 2)
			# Draw chain
			draw_texture(chain_img,temppos,Color(1,1,1,1))
		# Stop editor code from being triggered
		return
	
	# Editor code
	# Calculate Sine and Cosine
	var editsin = sin(deg_to_rad(sin(deg_to_rad(edittime)) * rotate_amount))
	var editcos = cos(deg_to_rad(sin(deg_to_rad(edittime)) * rotate_amount))
	# Draw Each Chain
	for i in chains:
		# Calculate Position
		temppos = Vector2(editsin * ((i + 1) * chain_size),editcos * ((i + 1) * chain_size))
		# Center chain
		temppos -= Vector2(float(chain_img.get_width()) / 2,float(chain_img.get_height()) / 2)
		# Draw chain
		draw_texture(chain_img,temppos,Color(1,1,1,1))
	# Draw distance of the swing's chains
	draw_arc(Vector2.ZERO,chains*chain_size + float(chain_size)/2,deg_to_rad(90+rotate_amount),deg_to_rad(90-rotate_amount),chain_size,Color(0.5,0,1,0.5),2)
	#draw_circle(Vector2.ZERO,chains*chain_size + chain_size/2,Color(0.5,0,1,0.5))
	# Draw moving platform
	temppos = Vector2(editsin * (chains * chain_size + (float(chain_size) / 2)),editcos * (chains * chain_size + (float(chain_size) / 2)))
	temppos -= Vector2(float(plat_img.get_width()) / 2,float(plat_img.get_height()) / 2)
	draw_texture(plat_img,temppos,Color(1,1,1,1))
	# Draw the possible bottom position
	temppos = Vector2(sin(deg_to_rad(0)) * (chains * chain_size + (float(chain_size) / 2)),cos(deg_to_rad(0)) * (chains * chain_size + (float(chain_size) / 2)))
	temppos -= Vector2(float(plat_img.get_width()) / 2,float(plat_img.get_height()) / 2)
	draw_texture(plat_img,temppos,Color(1,1,1,0.25))
	# Draw the possible right position
	temppos = Vector2(sin(deg_to_rad(rotate_amount)) * (chains * chain_size + (float(chain_size) / 2)),cos(deg_to_rad(rotate_amount)) * (chains * chain_size + (float(chain_size) / 2)))
	temppos -= Vector2(float(plat_img.get_width()) / 2,float(plat_img.get_height()) / 2)
	draw_texture(plat_img,temppos,Color(1,1,1,0.25))
	# Draw the possible left position
	temppos = Vector2(sin(deg_to_rad(-rotate_amount)) * (chains * chain_size + (float(chain_size) / 2)),cos(deg_to_rad(-rotate_amount)) * (chains * chain_size + (float(chain_size) / 2)))
	temppos -= Vector2(float(plat_img.get_width()) / 2,float(plat_img.get_height()) / 2)
	draw_texture(plat_img,temppos,Color(1,1,1,0.25))
