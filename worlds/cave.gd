extends World

@onready var boar_boss: CharacterBody2D = $BoarBoss



func _on_boar_boss_died() -> void:
	await get_tree().create_timer(1).timeout
	Game.change_scene("res://ui/game_end_screen.tscn",{duration=1})
