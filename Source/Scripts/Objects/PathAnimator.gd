tool
extends Area2D

export var startFrame = 48;
export var endFrame = 59;
export var animLoops = 1;
onready var path = $Path;

var player = preload("res://Graphics/Players/Sonic.png");


func _process(delta):
	if Engine.editor_hint:
		path = $Path;
		update();

func _draw():
	if Engine.editor_hint:
		var frames = (endFrame-startFrame+1)*animLoops;
		
		for i in range(frames):
			var offset = float(i)/frames;
			var id = min((path.curve.get_point_count()-1)*offset,path.curve.get_point_count()-1);
			
			i = fmod(i,frames/animLoops);
			var calcFrame = fmod(startFrame+i,16);
			
			draw_texture_rect_region(player,Rect2(-Vector2(24,24)+path.curve.interpolate(floor(id),fmod(id,1)),Vector2(48,48)),
			Rect2(Vector2(48*calcFrame,48*floor(float(startFrame+i)/16)),Vector2(48,48)),Color(1,1,1,0.5));



func _player_touch(body):
	if !Engine.editor_hint:
		if (body.has_method("set_state") && body.currentState != body.STATES.ANIMATION):
			body.set_state(body.STATES.ANIMATION);
			body.animator.stop();
			var animatorNode = body.stateList[body.STATES.ANIMATION];
			animatorNode.path = self;
			animatorNode.offset = 0;
