tool
extends Node2D


# origin offset
var offset = Vector2.ZERO;

# editor mode, 0 = edit, 1 = copy
var mode = 0;

# used for referencing the mode
const EDIT = 0;
const COPY = 1;

# Mouse buttons
var rmbPress = false;
var lmbPress = false;

# get Paret, Parent has to be TileMap
var parent = get_parent();

# editor settings
export var active = false;
export (int, "None", "Tilemap", "Custom") var template = 0;

# Button to copy current tile layout to clipboard (paste this under STAMPS)
export var copyLayoutToClipboard = false;

# used to pick the template set, just add a name for your set onto the list to match STAMPS
export (int, "no template", "Default template") var set = 0;

# stamps
# you may want to put these in their own global script file if you plan on modifying
# this area to prevent lag
const STAMPS = [null,
[9,0,0,0,2,0,0,10,0,0,1,2,0,0,11,0,0,2,2,0,0,12,0,0,3,2,0,0,13,0,0,0,3,0,0,14,0,0,1,3,0,0,15,0,0,2,3,0,0,2,1,0,2,0,1,0,3,1,0,2,1,1,0,4,1,0,2,1,0,0,5,1,0,2,0,0,0,9,1,0,1,2,0,0,10,1,0,2,2,0,0,11,1,0,3,2,0,0,12,1,0,0,3,0,0,13,1,0,1,3,0,0,14,1,0,2,3,0,0,15,1,0,0,2,0,0,26,1,0,0,0,0,0,0,2,0,2,0,1,0,1,2,0,2,1,1,0,2,2,0,0,0,0,0,3,2,0,0,0,0,0,4,2,0,0,0,0,0,5,2,0,0,0,0,0,6,2,0,2,1,0,0,7,2,0,2,0,0,0,9,2,0,2,2,0,0,10,2,0,3,2,0,0,11,2,0,0,3,0,0,12,2,0,1,3,0,0,13,2,0,2,3,0,0,14,2,0,0,2,0,0,15,2,0,1,2,0,0,26,2,0,3,3,0,0,9,3,0,3,2,0,0,10,3,0,0,3,0,0,11,3,0,1,3,0,0,12,3,0,2,3,0,0,13,3,0,0,2,0,0,14,3,0,1,2,0,0,15,3,0,2,2,0,0,26,3,0,3,3,0,0,9,4,0,0,3,0,0,10,4,0,1,3,0,0,11,4,0,2,3,0,0,12,4,0,0,2,0,0,13,4,0,1,2,0,0,14,4,0,2,2,0,0,15,4,0,3,2,0,0,25,4,0,0,0,0,0,26,4,0,3,3,0,0,27,4,0,0,0,0,0,28,4,0,0,0,0,0,29,4,0,0,0,0,0,0,5,0,0,0,0,0,1,5,0,0,0,0,0,2,5,0,0,0,0,0,3,5,0,0,0,0,0,4,5,0,0,0,0,0,5,5,0,0,0,0,0,6,5,0,0,0,0,0,7,5,0,0,0,0,0,9,5,0,1,3,0,0,10,5,0,2,3,0,0,11,5,0,0,2,0,0,12,5,0,1,2,0,0,13,5,0,2,2,0,0,14,5,0,3,2,0,0,15,5,0,0,3,0,0,25,5,0,0,0,0,0,26,5,0,3,3,0,0,27,5,0,0,0,0,0,28,5,0,0,0,0,0,29,5,0,0,0,0,0,0,6,0,0,0,0,0,1,6,0,0,0,0,0,2,6,0,0,0,0,0,3,6,0,0,0,0,0,4,6,0,0,0,0,0,5,6,0,0,0,0,0,6,6,0,0,0,0,0,7,6,0,0,0,0,0,9,6,0,2,3,0,0,10,6,0,0,2,0,0,11,6,0,1,2,0,0,12,6,0,2,2,0,0,13,6,0,3,2,0,0,14,6,0,0,3,0,0,15,6,0,1,3,0,0,26,6,0,3,3,0,0,28,6,0,1,1,1,0,29,6,0,1,1,0,0,26,7,0,3,3,1,0,18,8,0,2,0,1,0,19,8,0,2,1,1,0,26,8,0,3,3,0,1,9,9,0,0,0,0,0,10,9,0,3,1,0,0,17,9,0,3,1,1,0,18,9,0,0,0,0,0,19,9,0,0,0,0,0,26,9,0,3,3,1,1,9,10,0,0,0,0,0,10,10,0,0,0,0,0,11,10,0,3,1,0,0,14,10,0,3,1,1,0,15,10,0,0,0,0,0,16,10,0,0,0,0,0,17,10,0,0,0,0,0,18,10,0,0,0,0,0,19,10,0,0,0,0,0,26,10,0,3,3,0,0,28,10,0,0,0,0,0,29,10,0,0,0,0,0,1,11,0,0,0,0,0,2,11,0,1,0,0,0,3,11,0,2,0,0,0,4,11,0,3,0,0,0,9,11,0,0,0,0,0,10,11,0,0,0,0,0,11,11,0,0,0,0,0,12,11,0,0,1,0,0,13,11,0,0,1,1,0,14,11,0,0,0,0,0,15,11,0,0,0,0,0,16,11,0,3,1,0,1,17,11,0,2,0,1,1,18,11,0,2,1,1,1,19,11,0,0,0,0,0,25,11,0,0,0,0,0,26,11,0,0,0,0,0,27,11,0,0,0,0,0,28,11,0,0,0,0,0,29,11,0,0,0,0,0,1,12,0,0,1,0,0,2,12,0,1,1,0,0,3,12,0,2,1,0,0,4,12,0,3,1,0,0,9,12,0,0,0,0,0,10,12,0,0,0,0,0,11,12,0,0,0,0,0,14,12,0,0,0,0,0,15,12,0,0,0,0,0,16,12,0,2,1,0,0,17,12,0,2,0,0,0,18,12,0,3,1,1,0,19,12,0,0,0,0,0,1,13,0,0,2,0,0,2,13,0,1,2,0,0,3,13,0,2,2,0,0,4,13,0,3,2,0,0,9,13,0,0,0,0,0,10,13,0,0,0,0,0,11,13,0,0,0,0,0,14,13,0,0,0,0,0,15,13,0,0,0,0,0,16,13,0,0,0,0,0,17,13,0,0,0,0,0,18,13,0,0,0,0,0,19,13,0,0,0,0,0,1,14,0,0,3,0,0,2,14,0,1,3,0,0,3,14,0,2,3,0,0,4,14,0,3,3,0,0,9,14,0,0,0,0,0,10,14,0,0,0,0,0,11,14,0,0,0,0,0,14,14,0,0,0,0,0,15,14,0,0,0,0,0,16,14,0,0,0,0,0,17,14,0,0,0,0,0,18,14,0,0,0,0,0,19,14,0,0,0,0,0,26,14,0,0,1,0,0,27,14,0,0,1,1,0,28,14,0,1,0,0,0,29,14,0,0,1,0,0,30,14,0,0,1,1,0,9,15,0,3,1,0,1,10,15,0,2,0,1,1,11,15,0,2,0,0,1,14,15,0,2,0,1,1,15,15,0,2,1,1,1,16,15,0,0,0,0,0,17,15,0,2,1,0,1,18,15,0,2,0,0,1,19,15,0,3,1,1,1,28,15,0,1,0,0,0,16,16,0,3,0,1,0,17,16,0,3,1,0,0,18,16,0,2,0,1,0,19,16,0,2,1,1,0,28,16,0,1,0,0,0,16,17,0,1,1,1,0,17,17,0,0,0,0,0,18,17,0,0,0,0,0,19,17,0,0,0,0,0,25,17,0,1,0,0,0,26,17,0,0,1,0,0,27,17,0,0,1,1,0,28,17,0,0,1,0,0,29,17,0,0,1,1,0,1,18,0,0,0,0,0,2,18,0,0,0,0,0,3,18,0,0,0,0,0,4,18,0,0,0,0,0,5,18,0,0,0,0,0,17,18,0,3,1,1,1,18,18,0,0,0,0,1,19,18,0,0,0,0,1,25,18,0,1,0,0,0,1,19,0,0,0,0,0,2,19,0,2,1,0,1,3,19,0,2,0,0,1,4,19,0,3,1,1,1,5,19,0,0,0,0,0,18,19,0,2,0,1,1,19,19,0,2,1,1,1,25,19,0,1,0,0,0,1,20,0,0,0,0,0,2,20,0,3,1,0,0,3,20,0,2,0,1,0,4,20,0,2,1,1,0,5,20,0,0,0,0,0,25,20,0,0,1,0,0,26,20,0,0,1,1,0,27,20,0,0,1,0,0,28,20,0,0,1,1,0,29,20,0,0,1,0,0,30,20,0,0,1,1,0,1,21,0,0,0,0,0,2,21,0,0,0,0,0,3,21,0,0,0,0,0,4,21,0,0,0,0,0,5,21,0,0,0,0,0,14,22,0,2,0,1,0,15,22,0,2,1,1,0,16,22,0,0,0,0,0,17,22,0,2,1,0,0,18,22,0,2,0,0,0,13,23,0,3,1,1,0,14,23,0,0,0,0,0,15,23,0,0,0,0,0,16,23,0,0,0,0,0,17,23,0,0,0,0,0,18,23,0,0,0,0,0,19,23,0,0,0,0,0,20,23,0,3,1,0,0,10,24,0,3,1,1,0,11,24,0,0,0,0,0,12,24,0,0,0,0,0,13,24,0,0,0,0,0,14,24,0,0,0,0,0,15,24,0,0,0,0,0,16,24,0,0,0,0,0,17,24,0,0,0,0,0,18,24,0,0,0,0,0,19,24,0,0,0,0,0,20,24,0,0,0,0,0,21,24,0,0,0,0,0,22,24,0,0,0,0,0,23,24,0,0,0,0,0,10,25,0,0,0,0,0,11,25,0,0,0,0,0,12,25,0,3,1,0,1,13,25,0,2,0,1,1,14,25,0,2,1,1,1,15,25,0,0,0,0,0,16,25,0,0,0,0,0,17,25,0,0,0,0,0,18,25,0,0,0,0,0,19,25,0,0,0,0,0,20,25,0,0,0,0,0,21,25,0,0,0,0,0,22,25,0,0,0,0,0,23,25,0,0,0,0,0,10,26,0,0,0,0,0,11,26,0,0,0,0,0,12,26,0,2,1,0,0,13,26,0,2,0,0,0,14,26,0,3,1,1,0,15,26,0,0,0,0,0,16,26,0,0,0,0,0,17,26,0,0,0,0,0,18,26,0,0,0,0,0,19,26,0,0,0,0,0,20,26,0,0,0,0,0,21,26,0,0,0,0,0,22,26,0,0,0,0,0,23,26,0,0,0,0,0,10,27,0,0,0,0,0,11,27,0,0,0,0,0,12,27,0,0,0,0,0,13,27,0,0,0,0,0,14,27,0,0,0,0,0,15,27,0,0,0,0,0,16,27,0,0,0,0,0,17,27,0,0,0,0,0,18,27,0,0,0,0,0,19,27,0,0,0,0,0,20,27,0,3,1,0,1,21,27,0,2,0,1,1,22,27,0,2,1,1,1,23,27,0,0,0,0,0,10,28,0,0,0,0,0,11,28,0,0,0,0,0,12,28,0,0,0,0,0,13,28,0,0,0,0,0,14,28,0,0,0,0,0,15,28,0,0,0,0,0,16,28,0,0,0,0,0,17,28,0,0,0,0,0,18,28,0,0,0,0,0,19,28,0,0,0,0,0,20,28,0,2,1,0,0,21,28,0,2,0,0,0,22,28,0,3,1,1,0,23,28,0,0,0,0,0],
];

# used for referencing the tile template node.
var templateGrid = null;

# = structure =
# 0 tile, 1 auto tile vector, 2 scale vectors
var pattern = [[[-1,Vector2.ZERO,Vector2.ZERO]]];
var squareSize = Vector2(1,1)

# get font
var label = Label.new()
var font = label.get_font("")

# buttons
const BUTTONS = {ACTIVE = Rect2(Vector2(0,-16),Vector2(40,16)),
TILES = Rect2(Vector2(0,-32),Vector2(40,16)),
FLIPX = Rect2(Vector2(0,-48),Vector2(40,16)),
FLIPY = Rect2(Vector2(0,-64),Vector2(40,16)),
STAMP = Rect2(Vector2(0,-80),Vector2(40,16))};


func _ready():
	# set parent
	parent = get_parent();
	active = false; # prevent your tiles from being placed when you open a room

func _process(delta):
	# get tile is used to determine what tile map to reference
	var getTile = parent;
	
	# if template exists use tat instead
	if (templateGrid):
		getTile = templateGrid;
	
	# grab temporary variables
	var cellSize = getTile.cell_size;
	var backOff = (getTile.get_local_mouse_position()/cellSize).floor()*cellSize;
	# min off is used to figure out what position reference to use for grabbing and placing tiles,
	# there shouldn't be any reason to move the child but just in case
	var minOff = Vector2(min(backOff.x,offset.x),min(backOff.y,offset.y));
	
	# code to copy to clipboard the current tilemap to clipboard
	if (copyLayoutToClipboard):
		var tileLayout = [];
		var rect = parent.get_used_rect();
		for cell in parent.get_used_cells():
			# generate the cell string, if this is changed it'll mess with the STAMPS so be careful
			tileLayout.append(cell.x); # 0
			tileLayout.append(cell.y); # 1
			tileLayout.append(parent.get_cell(cell.x,cell.y)); # 2
			tileLayout.append(parent.get_cell_autotile_coord(cell.x,cell.y).x); # 3
			tileLayout.append(parent.get_cell_autotile_coord(cell.x,cell.y).y); # 4
			tileLayout.append(int(parent.is_cell_x_flipped(cell.x,cell.y))); # 5
			tileLayout.append(int(parent.is_cell_y_flipped(cell.x,cell.y))); # 6
		
		# copy tile string to clipboard
		OS.set_clipboard(str(tileLayout).replace(" ",""));
		
		# reset clipboard variable to prevent godot from copying too much
		copyLayoutToClipboard = false;
	
	# check for active to prevent 
	if (!active):
		
		#Active Button
		if (!Input.is_mouse_button_pressed(BUTTON_LEFT)):
			# check if mouse is pressed, not held
			if (lmbPress):
				if (BUTTONS.ACTIVE.intersects(Rect2(get_local_mouse_position(),Vector2(1,1)))):
					active = true;
				# deactivate left mouse
				lmbPress = false;
		else:
			# set left mouse
			lmbPress = true;
		return false;
	
	# stamp tiles
	if (template == 2):
		# check that template grid doesn't exist
		if (templateGrid == null):
			# generate new tile map
			templateGrid = TileMap.new();
			templateGrid.name = "template";
			self.add_child(templateGrid);
			templateGrid.set_owner(get_tree().get_edited_scene_root());
			
			# inherit settings
			templateGrid.tile_set = parent.tile_set;
			templateGrid.cell_size = parent.cell_size;
			
			# make the new tilemap use the current stamps (if stamps isn't null)
			if (STAMPS[set] != null && set < STAMPS.size()):
				for i in (STAMPS[set].size()):
					var off = (i*7);
					templateGrid.set_cell(
					STAMPS[set][off],STAMPS[set][off+1],           # positions
					STAMPS[set][off+2],                            # tile
					STAMPS[set][off+5],STAMPS[set][off+6],         # x and y flips
					false,
					Vector2(STAMPS[set][off+3],STAMPS[set][off+4]) # tile offset
					);
			else:
				print("Stamp set does not exist");
	else: # turn off stamps
		# clear any children
		for i in get_children():
			i.queue_free();
		templateGrid = null;
	
	
	# button release
	if (!Input.is_mouse_button_pressed(BUTTON_LEFT)):
		if (lmbPress):
			lmbPress = false;
			
			# Deactivate
			if (BUTTONS.ACTIVE.intersects(Rect2(get_local_mouse_position(),Vector2(1,1)))):
				active = false;
				# update buttons
				update();
				return false;
			# Tile Switch
			elif (BUTTONS.TILES.intersects(Rect2(get_local_mouse_position(),Vector2(1,1)))):
				template = int(template != 1);
				return false;
			# Flip X
			elif (BUTTONS.FLIPX.intersects(Rect2(get_local_mouse_position(),Vector2(1,1)))):
				var tempArray = [];
				tempArray.resize(pattern.size());
				for i in pattern.size():
					tempArray[i] = pattern[pattern.size()-i-1].duplicate(true);
					# invert the x flips
					for j in tempArray[i].size():
						tempArray[i][j][2].x = int(tempArray[i][j][2].x == 0);
				pattern = tempArray;
				return false;
			
			# Flip Y
			elif (BUTTONS.FLIPY.intersects(Rect2(get_local_mouse_position(),Vector2(1,1)))):
				var tempArray = [];
				tempArray.resize(pattern.size());
				# have to loop through x and y arrays for this
				for i in pattern.size():
					tempArray[i] = [];
					tempArray[i].resize(pattern[i].size());
					for j in pattern[i].size():
						tempArray[i][j] = pattern[i][pattern[i].size()-j-1].duplicate(true);
						# invert the y flips
						tempArray[i][j][2].y = int(tempArray[i][j][2].y == 0);
				pattern = tempArray;
				return false;
			
			# Stamp menu
			elif (BUTTONS.STAMP.intersects(Rect2(get_local_mouse_position(),Vector2(1,1)))):
				template = int(template == 0)*2;
			
			
			# Copy Tilesets
			elif (template == 1):
				# get mouse
				var mouse = (minOff-position)/cellSize;
				# set the pattern
				pattern.resize((squareSize/cellSize).x);
				
				for i in pattern.size():
					pattern[i] = [];
					pattern[i].resize((squareSize/cellSize).y);
					for j in pattern[i].size():
						#set default tile to nothing
						pattern[i][j] = [-1,Vector2.ZERO,Vector2.ZERO];
						
						# xOff is used to calculate the next tile offset
						var xOff = 0;
						var count = 0;
						
						# loop through tilesets
						for id in parent.tile_set.get_tiles_ids():
							if (pattern[i][j][0] == -1):
								while (count < id):
									xOff += parent.tile_set.tile_get_region(count).size.x;
									count += 1;
								# if mouse is inside tileset region, copy patterns
								if (minOff.x-position.x+(i*cellSize.x) >= xOff &&
								minOff.x-position.x+(i*cellSize.x) < xOff+parent.tile_set.tile_get_region(count).size.x &&
								minOff.y-position.y+(j*cellSize.y) >= 0 &&
								minOff.y-position.y+(j*cellSize.y) < parent.tile_set.tile_get_region(count).size.y):
									pattern[i][j] = [
									id,
									mouse.floor()+Vector2(i,j)-Vector2(xOff/cellSize.x,0),
									Vector2.ZERO];
			
			# copy mode or template mode, copys the tile range (uses getTile)
			elif (mode == COPY || template == 2):
				pattern.resize((squareSize/cellSize).x);
				for i in pattern.size():
					pattern[i] = [];
					pattern[i].resize((squareSize/cellSize).y);
					for j in pattern[i].size():
						pattern[i][j] = [getTile.get_cell((minOff.x/cellSize.x)+i,(minOff.y/cellSize.y)+j),
						getTile.get_cell_autotile_coord((minOff.x/cellSize.x)+i,(minOff.y/cellSize.y)+j),
						Vector2(getTile.is_cell_x_flipped((minOff.x/cellSize.x)+i,(minOff.y/cellSize.y)+j),
						getTile.is_cell_y_flipped((minOff.x/cellSize.x)+i,(minOff.y/cellSize.y)+j))];
			
			# paste mode
			else:
				if (mode == EDIT && pattern.size() > 0):
					for i in (squareSize.x/cellSize.x):
						for j in (squareSize.y/cellSize.y):
							
							var loopArea = Vector2(fposmod (i,pattern.size()),fposmod (j,pattern[0].size()));
							
							parent.set_cell((minOff.x/16)+i,(minOff.y/16)+j,
							pattern[loopArea.x][loopArea.y][0],
							pattern[loopArea.x][loopArea.y][2].x,
							pattern[loopArea.x][loopArea.y][2].y,false,
							pattern[loopArea.x][loopArea.y][1]);
				# check that pattern size is not 0
				if (pattern.size() > 0):
					squareSize = Vector2(pattern.size(),pattern[0].size())*cellSize;
				else:
				# default to 1
					squareSize = Vector2(1,1)*cellSize;
		
		# set offset to mouse position (if not clicking)
		# offset is used to determine the origin of a square
		offset = (getTile.get_local_mouse_position()/cellSize).floor()*cellSize;
	
	# press left mouse
	if (Input.is_mouse_button_pressed(BUTTON_LEFT) && !lmbPress):
		lmbPress = true;
	
	# set square size if clicking
	# holding left mouse
	if (lmbPress):
		squareSize = cellSize+(((getTile.get_local_mouse_position()/cellSize).floor()*cellSize)-offset).abs();
	
	# Right mouse button press
	# this section mostly just switches between copy and paste
	if (Input.is_mouse_button_pressed(BUTTON_RIGHT) && !rmbPress):
		# originally I was going to include more modes but found out I couldn't
		# do keyboard input and just condensed it down to copy and paste
		if (mode < 1):
			mode += 1;
			print("Copy mode activated");
		else:
			mode = 0;
			print("Paste mode activated");
		rmbPress = true;
	
	# Release right mouse
	if (!Input.is_mouse_button_pressed(BUTTON_RIGHT)):
		rmbPress = false;
	update();
	

func _draw():
	# this is similar to the temporary variables in process
	var getTile = parent;
	if (templateGrid):
		getTile = templateGrid;
		# if in template mode draw a black rectangle to indicate the region
		draw_rect(Rect2(getTile.get_used_rect().position,(getTile.get_used_rect().size+Vector2.RIGHT)*getTile.cell_size),Color(0,0,0,0.9));
		
	var cellSize = getTile.cell_size;
	var backOff = (getTile.get_local_mouse_position()/cellSize).floor()*cellSize;
	var minOff = Vector2(min(backOff.x,offset.x),min(backOff.y,offset.y));
	
	
	
	
	
	
	
	if (active):
		# draw raw tileset if in tileset menu
		if (template == 1):
			var xOff = 0;
			for i in parent.tile_set.get_tiles_ids():
				
				draw_rect(Rect2(Vector2(xOff,0),parent.tile_set.tile_get_region(i).size),Color(0,0,0,0.9));
				draw_texture_rect_region(
				parent.tile_set.tile_get_texture(i),
				Rect2(Vector2(xOff,0),parent.tile_set.tile_get_region(i).size),
				parent.tile_set.tile_get_region(i)
				);
				
				xOff += parent.tile_set.tile_get_region(i).size.x;
		
		# use a position priority, mostly used for the template menu
		var positionPriority = position;
		if (get_child_count() > 0):
			positionPriority = getTile.position;
		
		# draw the selection square
		draw_rect(Rect2(minOff-positionPriority,squareSize),Color(1-int(mode == 1),1-int(mode == 2),1,0.25));
	
	
	
		# draw template
		if (!lmbPress):
			if (pattern.size() > 0):
				for i in pattern.size():
					for j in pattern[i].size():
						if (pattern[i][j][0] != -1):
							draw_texture_rect_region(parent.tile_set.tile_get_texture(pattern[i][j][0]),
							Rect2((minOff+Vector2(i,j)*cellSize)-positionPriority,cellSize),
							Rect2(parent.tile_set.tile_get_region(pattern[i][j][0]).position+(pattern[i][j][1]*cellSize),cellSize*convert_flips(pattern[i][j][2])),Color(1,1,1,0.25));
		# draw tiles
		elif(mode == EDIT):
			if (pattern.size() > 0):
				for i in (squareSize.x/cellSize.x):
					for j in (squareSize.y/cellSize.y):
						var loopArea = Vector2(fposmod (i,pattern.size()),fposmod (j,pattern[0].size()));
						if (pattern[loopArea.x][loopArea.y][0] != -1):
							draw_texture_rect_region(parent.tile_set.tile_get_texture(pattern[loopArea.x][loopArea.y][0]),
							Rect2((minOff+Vector2(i,j)*cellSize)-positionPriority,cellSize),
							Rect2(parent.tile_set.tile_get_region(pattern[loopArea.x][loopArea.y][0]).position+(pattern[loopArea.x][loopArea.y][1]*cellSize),cellSize*convert_flips(pattern[loopArea.x][loopArea.y][2])),Color(1,1,1,1));
	
	
	
	
	
	# Interface Buttons
	# this section draws a rectangle and string based on BUTTONS
	# this would be where you add more buttons visually
	draw_rect(BUTTONS.ACTIVE,Color(1,1,1,0.2+(float(active)*0.5)));
	draw_string(font,BUTTONS.ACTIVE.position+Vector2(0.5,14),"Active");
	draw_rect(BUTTONS.TILES,Color(1,1,1,0.2+(float(template == 1)*0.5)));
	draw_string(font,BUTTONS.TILES.position+Vector2(0.5,14),"Tiles");
	
	draw_rect(BUTTONS.FLIPX,Color(1,1,1,0.2));
	draw_string(font,BUTTONS.FLIPX.position+Vector2(0.5,14),"Flip X");
	draw_rect(BUTTONS.FLIPY,Color(1,1,1,0.2));
	draw_string(font,BUTTONS.FLIPY.position+Vector2(0.5,14),"Flip Y");
	
	draw_rect(BUTTONS.STAMP,Color(1,1,1,0.2+float(template == 2)*0.5));
	draw_string(font,BUTTONS.STAMP.position+Vector2(0.5,14),"Stamp");
	
	

# quick function for converting the flip booleans into a vector2 scale
func convert_flips(flips = Vector2(0,0)):
	return Vector2(1-flips.x*2,1-flips.y*2);
