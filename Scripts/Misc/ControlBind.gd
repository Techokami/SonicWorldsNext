extends Button

@export var bind = "gm_action"
@onready var control = get_parent()
var active = false

func _ready():
	# check that playerControlIndex is in parent. if it isn't get the second parent
	if control.get("playerControlIndex") == null:
		control = get_parent().get_parent()
	var _con = connect("pressed",Callable(self,"lock_in_button"))

# input remaping
func _unhandled_input(event):
	# check if active
	if active:
		# set event action
		if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
			# check if player 2 settings
			var p2Text = ""
			# if player index is 1 then add _P2 to the p2Text
			if control.playerControlIndex == 1:
				p2Text = "_P2"
			
			# add new event
			InputMap.action_add_event(bind+p2Text,event)
			active = false
			text = "_"
			control.bindButton = null
			control.update_display()
	

func _input(_event):
	# check if hovering
	if is_hovered():
		# check if not blank (blank so that we can disable confusing the controller checker
		if bind != "":
			if control.bindButton == null:
				control.bindButton = self
				control.update_display()
			elif control.bindButton != self: # disable if other bind button in use
				disabled = true
		elif control.bindButton != null:
			disabled = true
	# else ignore (remove self from control binds if we're being focussed)
	else:
		if control.bindButton == self and !active:
			control.bindButton = null
			control.update_display()
		disabled = false

func lock_in_button():
	if control.bindButton == self:
		text = "..."
		active = true
