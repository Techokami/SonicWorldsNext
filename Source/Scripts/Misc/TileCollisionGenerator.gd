tool
extends Sprite

var surfacePattern = [];
var polygon = [];

export var activate = false;

export var currentOffset = Vector2.ZERO;
export var grid = Vector2(16,16);


func _process(delta):
	if Engine.editor_hint:
		if (activate):
			polygon.clear();
		
			surfacePattern.clear();
			surfacePattern.append(Vector2.RIGHT);
			var curPat = 0;
			
			activate = false;
			
			var image = texture.get_data();
			image.lock();
			
			var pose = Vector2.ZERO;
			
			# find top left corner
			while (polygon.size() == 0 && (pose.x < 16 || pose.y < 16)):
				if (round(get_pixel(image,currentOffset+pose).a) == 0):
					if (pose.y < 15):
						pose.y += 1;
					else:
						pose.x += 1;
						pose.y = 0;
				else:
					# set top left corner
					polygon.append(pose);
			
			# find end of shape
			if (polygon.size() > 0):
				pose.x = 15;
				while (round(get_pixel(image,currentOffset+pose).a) == 0):
					if (pose.y < 15):
						pose.y += 1;
					else:
						pose.x -= 1;
						pose.y = 0;
			
			surfacePattern[curPat] = (pose-polygon[0]).normalized();
			
			while (round(get_pixel(image,currentOffset+pose).a) == 1 && pose.x < grid.x && pose.y < grid.y):
				pose += surfacePattern[curPat].normalized().round();
			
			#if (surfacePattern[curPat].y >= 0.5 || pose.x < (grid.x-1)):
			#	while (round(get_pixel(image,currentOffset+pose).a) == 1 && pose.y < 16):
			#		pose.y += 1;
			
			#edge cases
			if (pose.x >= grid.x-1):
				pose.x = grid.x;
			
			
			polygon.append(pose);
			
			# check in terrain
			if (round(get_pixel(image,currentOffset+polygon[0].linear_interpolate(polygon[1],0.5)
			+(polygon[0]-polygon[1]).rotated(deg2rad(90)).normalized()).a) == 1):
				
				polygon.append(polygon[1]);
				polygon[1] = polygon[0];
				# check edge
				if (polygon[1].y == 0):
					while (round(get_pixel(image,currentOffset+polygon[1].linear_interpolate(polygon[2],0.5)
					+(polygon[0]-polygon[2]).rotated(deg2rad(90)).normalized()*0.5).a) == 1):
#					+polygon[1].linear_interpolate(polygon[2],0.5).rotated(deg2rad(-90)).normalized()*0.5).a) == 1):
						polygon[1].x += 1;
				else:
					polygon[1] = polygon[0].linear_interpolate(polygon[2],0.5);
					while (round(get_pixel(image,currentOffset+polygon[1]).a) == 1
					&& polygon[1].y > 0 && polygon[1].y < grid.y-1
					&& polygon[1].x > 0 && polygon[1].x < grid.x-1):
						polygon[1] += (polygon[0]-polygon[2]).rotated(deg2rad(90)).normalized()*0.3;
				polygon[1].x = clamp(polygon[1].x,0,grid.x-1);
				polygon[1].y = clamp(polygon[1].y,0,grid.y-1);
					
			
			# check if not touching terrain midway
			elif (round(get_pixel(image,currentOffset+polygon[0].linear_interpolate(polygon[1],0.5)
			+(polygon[0]-polygon[1]).rotated(deg2rad(-90)).normalized()).a) == 0):
				print("A");
			#+polygon[0].linear_interpolate(polygon[1],0.5).rotated(deg2rad(90)).normalized()*0.5).a) == 0):
				polygon.append(polygon[1]);
				polygon[1] = polygon[0].linear_interpolate(polygon[2],0.5);

				while (round(get_pixel(image,currentOffset+polygon[1]).a) == 0
				&& polygon[1].y > 0 && polygon[1].y < grid.y-1
				&& polygon[1].x > 0 && polygon[1].x < grid.x-1):
					polygon[1] += (polygon[0]-polygon[2]).rotated(deg2rad(-90)).normalized()*0.3;
				polygon[1].x = clamp(polygon[1].x,0,grid.x-1);
				polygon[1].y = clamp(polygon[1].y,0,grid.y-1);
#				while (round(get_pixel(image,currentOffset+polygon[1].linear_interpolate(polygon[2],0.5)
#				+polygon[1].linear_interpolate(polygon[2],0.5).rotated(deg2rad(90)).normalized()*0.5).a) == 0):
#					polygon[1] += polygon[0].linear_interpolate(polygon[2],0.5).rotated(deg2rad(90))*0.3;
			
			# bottom edge case
			if (pose.y >= grid.y-1):
				var dir = (polygon[polygon.size()-1]-polygon[polygon.size()-2]).normalized();
				print(dir);
				if (round(get_pixel(image,currentOffset+polygon[polygon.size()-1]-Vector2(1,round(dir.normalized().y*2))).a) == 0 || polygon[polygon.size()-1].x < grid.x-1):
					polygon[polygon.size()-1].y = grid.y;
				while (round(get_pixel(image,currentOffset+polygon[polygon.size()-1]-Vector2(0,1)).a) == 1 && polygon[polygon.size()-1].x < 15):
					polygon[polygon.size()-1].x += 1;
			
			
#			var heightMap = [];
#			var count = 0;
#			for i in range(15):
#				count = 0;
#				for j in range(15):
#					if (round(get_pixel(image,currentOffset+Vector2(i,j)).a) == 1):
#						count += 1;
#				heightMap.append(count);
#			print(heightMap);
			
			#print(polygon);
		update();

func get_pixel(image,getOffset):
	return image.get_pixel(getOffset.x,getOffset.y);

func _draw():
	if Engine.editor_hint:
		draw_rect(Rect2(currentOffset,grid),Color(0,0,0.5,0.25));
		if (polygon.size() > 0):
			for i in polygon.size():
				if (i < polygon.size()-1):
					draw_line(currentOffset+polygon[i],currentOffset+polygon[i+1],Color.orangered);
					draw_circle(currentOffset+polygon[i].linear_interpolate(polygon[i+1],0.5),0.5,Color.blue);
					
					draw_line(currentOffset+polygon[i].linear_interpolate(polygon[i+1],0.5)+(polygon[i]-polygon[i+1]).rotated(deg2rad(-90)).clamped(4),
					currentOffset+polygon[i].linear_interpolate(polygon[i+1],0.5)+(polygon[i]-polygon[i+1]).rotated(deg2rad(90)).clamped(4),Color.green);
					
				draw_circle(currentOffset+polygon[i],0.5,Color.red);
