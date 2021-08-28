class_name InputLabel
extends Label

enum ControlType {
	Keyboard = 1,
	Joypad = 2,
	Touch = 4,
	XBox = 8 | 2,
	Playstation = 16 | 2,
}


export(Array, String) var actions := []

var backing_text := ""
var last_control_type: int = ControlType.Keyboard


func _ready() -> void:
	backing_text = text
	make_string()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSLATION_CHANGED:
			make_string()


func _unhandled_input(event):
	if event is InputEventKey or event is InputEventMouse \
			and last_control_type != ControlType.Keyboard:
		last_control_type = ControlType.Keyboard
		make_string()
		return
	if event is InputEventJoypadButton or event is InputEventJoypadMotion \
			and !(last_control_type & ControlType.Joypad):
		match Input.get_joy_guid(event.device):
			"__XINPUT_DEVICE__":
				last_control_type = ControlType.XBox
			"030000004c050000cc09000000000000":
				last_control_type = ControlType.Playstation
			_:
				print("Unknown input device (Please report): ", Input.get_joy_guid(event.device))
				last_control_type = ControlType.Joypad
		make_string()


func make_string() -> void:
	var controls := []
	for action in actions:
		assert(InputMap.has_action(action))
		var found_event := false
		for event in InputMap.get_action_list(action):
			if last_control_type == ControlType.Keyboard and event is InputEventKey:
				controls.push_back(event.as_text())
				found_event = true
				break
			elif last_control_type & ControlType.Joypad and event is InputEventJoypadButton:
				controls.push_back(_get_joy_button_name(event.button_index))
				found_event = true
				break
			elif last_control_type & ControlType.Joypad and event is InputEventJoypadMotion:
				controls.push_back(Input.get_joy_axis_string(event.axis))
				found_event = true
				break
		if !found_event:
			controls.push_back("n/a")
	text = tr(backing_text) % controls # if you get a debug break here, the translation is broken


func _get_joy_button_name(button_index: int) -> String:
	if last_control_type == ControlType.Playstation:
		return _get_playstation_button_name(button_index)
	else: # we don't know what the controller is. XBox is probably more common on desktops
		return _get_xbox_button_name(button_index)


func _get_xbox_button_name(button_index: int) -> String:
	match button_index:
		JOY_XBOX_A:
			return "A"
		JOY_XBOX_B:
			return "B"
		JOY_XBOX_X:
			return "X"
		JOY_XBOX_Y:
			return "Y"
		JOY_L3:
			return "Left Stick"
		JOY_R3:
			return "Right Stick"
		JOY_DPAD_UP:
			return "DPAD Up"
		JOY_DPAD_DOWN:
			return "DPAD Down"
		JOY_DPAD_LEFT:
			return "DPAD Left"
		JOY_DPAD_RIGHT:
			return "DPAD Right"
		JOY_SELECT:
			return "Back"
		JOY_START:
			return "Start"
		JOY_L:
			return "LB"
		JOY_L2:
			return "LT"
		JOY_R:
			return "RB"
		JOY_R2:
			return "RT"
		_:
			assert(false) # Add button to list above
			return "n/a"


func _get_playstation_button_name(button_index: int) -> String:
	match button_index:
		JOY_SONY_X:
			return "X"
		JOY_SONY_CIRCLE:
			return "Circle"
		JOY_SONY_SQUARE:
			return "Square"
		JOY_SONY_TRIANGLE:
			return "Triangle"
		JOY_L3:
			return "Left Stick"
		JOY_R3:
			return "Right Stick"
		JOY_DPAD_UP:
			return "DPAD Up"
		JOY_DPAD_DOWN:
			return "DPAD Down"
		JOY_DPAD_LEFT:
			return "DPAD Left"
		JOY_DPAD_RIGHT:
			return "DPAD Right"
		JOY_SELECT:
			return "Share"
		JOY_START:
			return "Options"
		JOY_L:
			return "L1"
		JOY_L2:
			return "L2"
		JOY_R:
			return "R1"
		JOY_R2:
			return "R2"
		_:
			assert(false) # Add button to list above
			return "n/a"


func _get_joy_axis_name(axis: int) -> String:
	if last_control_type == ControlType.Playstation:
		return _get_playstation_axis_name(axis)
	else: # we don't know what the controller is. XBox is probably more common on desktops
		return _get_xbox_axis_name(axis)


func _get_xbox_axis_name(axis: int) -> String:
	match axis:
		JOY_ANALOG_LX:
			return "Left Stick Horizontal"
		JOY_ANALOG_LY:
			return "Left Stick Vertical"
		JOY_ANALOG_RX:
			return "Right Stick Horizontal"
		JOY_ANALOG_RY:
			return "Right Stick Vertical"
		JOY_ANALOG_L2:
			return "LT"
		JOY_ANALOG_R2:
			return "RT"
		_:
			assert(false) # Add button to list above
			return "n/a"


func _get_playstation_axis_name(axis: int) -> String:
	match axis:
		JOY_ANALOG_LX:
			return "Left Stick Horizontal"
		JOY_ANALOG_LY:
			return "Left Stick Vertical"
		JOY_ANALOG_RX:
			return "Right Stick Horizontal"
		JOY_ANALOG_RY:
			return "Right Stick Vertical"
		JOY_ANALOG_L2:
			return "L2"
		JOY_ANALOG_R2:
			return "R2"
		_:
			assert(false) # Add button to list above
			return "n/a"
