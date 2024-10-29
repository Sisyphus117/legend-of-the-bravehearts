extends Control

@onready var label: Label = $Pause/pause/Label

func _ready() -> void:
	visible = true
	if OS.get_name() == "Android":
		label.visible = true
	else:
		label.visible = false
