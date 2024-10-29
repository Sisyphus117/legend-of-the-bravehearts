extends Control

@onready var game_start: Button = $VBoxContainer/GameStart
@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var game_load: Button = $VBoxContainer/GameLoad

func _ready() ->void:
	if not Game.has_save():
		game_load.disabled=true
	game_start.grab_focus()
	SoundManager.setup_ui_sounds(self)
	SoundManager.play_bgm(preload("res://assets/bgm/02 1 titles LOOP.mp3"))


func _on_game_start_pressed() -> void:
	Game.new_game()


func _on_game_load_pressed() -> void:
	Game.load_game()


func _on_game_exit_pressed() -> void:
	get_tree().quit()
