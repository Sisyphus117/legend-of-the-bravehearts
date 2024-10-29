extends Control
@onready var resume: Button = $VBoxContainer/Actions/HBoxContainer/Resume

func _ready() ->void:
	SoundManager.setup_ui_sounds(self)
	hide()
	visibility_changed.connect(func ():
		get_tree().paused=visible
		)
	#set_process_input(false)

func _input(event:InputEvent) ->void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		hide()
		get_parent().get_node("VirtualJoypad").visible = true
		Game.save_config()
		get_window().set_input_as_handled()


func show_pause() ->void:
	show()
	get_parent().get_node("VirtualJoypad").visible = false
	resume.grab_focus()

func _on_resume_pressed() -> void:
	get_parent().get_node("VirtualJoypad").visible = true
	hide()


func _on_quit_pressed() -> void:
	Game.back_to_title()
