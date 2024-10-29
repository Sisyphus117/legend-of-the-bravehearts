extends AnimatedSprite2D

const STICK_DEADZONE:float=0.3
const MOUSE_DEADZONE:float=16.0
func _ready() -> void:
	if Input.get_connected_joypads():
		show_joypad_icon(0)
	else:
		play("keyboard")

func _input(event: InputEvent) -> void:
	if(
		event is InputEventJoypadButton or 
		event is InputEventJoypadMotion and abs(event.axis_value) >STICK_DEADZONE
	):
		show_joypad_icon(event.device)
	if(
		event is InputEventKey or
		event is InputEventMouseButton or 
		event is InputEventMouseMotion and abs(event.velocity.length()) >MOUSE_DEADZONE		
	):
		play("keyboard")
		
func show_joypad_icon(device:int) ->void:
	var name:=Input.get_joy_name(device)
	if "Nintendo" in name:
		play("ninrendo")
	elif "DualShock" in name or "PS" in name:
		play("playstation")
	else:
		play("xbox")
