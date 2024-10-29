extends Status_panel

@onready var energy_bar: TextureProgressBar = $VBoxContainer/EnergyBar


func _ready()->void:
	if not stats:
		stats=Game.player_stats
	stats.energy_changed.connect(update_energy)
	update_energy()
	stats.health_changed.connect(update_health)
	update_health(false)
	
	tree_exited.connect(func():
		stats.energy_changed.disconnect(update_energy)
		stats.health_changed.disconnect(update_health)
		)
	
func update_energy() ->void:
	var percentage:=stats.energy/float(stats.max_energy)
	#energy_bar.value=percentage
	create_tween().tween_property(energy_bar,"value",percentage,0.2)

func update_health(should_update:=true) ->void:
	var percentage:=stats.health/float(stats.max_health)
	health_bar.value=percentage
	if should_update:
		create_tween().tween_property(eased_health_bar,"value",percentage,0.5)
	else:
		eased_health_bar.value=percentage
