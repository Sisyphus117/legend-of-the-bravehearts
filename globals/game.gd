extends CanvasLayer

const SAVE_PATH:="user://data.sav"
const CONFIG_PATH:="user://config.ini"
var key = PackedByteArray([0xa3, 0xf1, 0xc3, 0xb4, 0x0d, 0x15, 0x43, 0x45,
						   0x6d, 0x37, 0x72, 0x29, 0xf4, 0xe1, 0xe9, 0xa2,
						   0xf1, 0x0a, 0x25, 0x68, 0xec, 0xbf, 0x02, 0x34,
						   0xec, 0x8c, 0x24, 0x4a, 0x1f, 0x67, 0xb4, 0x56])

@onready var player_stats: Stats = $PlayerStats
@onready var color_rect: ColorRect = $ColorRect
@onready var default_player_status:=player_stats.to_dict()

var world_states:={}

signal camera_should_shake(amount:float)

func _ready() ->void:
	color_rect.color.a=0
	load_config()
	

func change_scene(path:String,params:Dictionary={},init:Callable=Callable()) ->void:
	var tree:=get_tree()
	var tween :=create_tween()
	var duration=params.get("duration",0.2)
	tree.paused=true
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect,"color:a",1,duration)
	await tween.finished
	  
	if tree.current_scene is World:
		var old_name:=tree.current_scene.scene_file_path.get_file().get_basename()
		world_states[old_name]=tree.current_scene.to_dict()
	

	tree.change_scene_to_file(path)
	if init:
		init.call()
	await tree.tree_changed
	
	if tree.current_scene is World:
		var new_name:=tree.current_scene.scene_file_path.get_file().get_basename()
		if new_name in world_states:
			tree.current_scene.from_dict(world_states[new_name])
	
	if "entry_point" in params:
		for node in tree.get_nodes_in_group("entry_points"):
			if node.name==params.entry_point:
				tree.current_scene.update_player(node.global_position,node.direction)
				break
	if "direction" in params and "position" in params:
		var position:Vector2=Vector2(params.position.x, params.position.y)
		tree.current_scene.update_player(position,params.direction)
	tree.paused=false
	tween=create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect,"color:a",0,duration)	
	 
func save_game() ->void:
	var tree:=get_tree()
	var scene:=tree.current_scene
	var scene_name:=scene.scene_file_path.get_file().get_basename()
	world_states[scene_name]=tree.current_scene.to_dict()
	
	var data :={
		world_states=world_states,
		stats=player_stats.to_dict(),
		scene=scene.scene_file_path,
		player={
			direction=scene.player.direction,
			position={
				x=scene.player.global_position.x,
				y=scene.player.global_position.y,
			}
		}
	}
	
	var json=JSON.stringify(data)
	var file:=FileAccess.open_encrypted(SAVE_PATH,FileAccess.WRITE,key)
	if not file :
		return
	file.store_string(json)

func load_game() ->void:
	var file:=FileAccess.open_encrypted(SAVE_PATH,FileAccess.READ,key)
	if not file :
		return
	var json:=file.get_as_text()
	var data:=JSON.parse_string(json) as Dictionary
	 #或data["stats"]
	change_scene(data.scene,data.player,func ():
		world_states=data.world_states
		player_stats.from_dict(data.stats))
	

func new_game() ->void:
	change_scene("res://worlds/forest.tscn",{duration=1},func ():
		world_states={}
		player_stats.from_dict(default_player_status))

func back_to_title() ->void:
	change_scene("res://ui/title_screen.tscn",{duration=1})
	

func has_save() ->bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_config() -> void:
	var config:=ConfigFile.new()
	
	config.set_value("audio","master",SoundManager.get_volume(SoundManager.Bus.MASTER))
	config.set_value("audio","sfx",SoundManager.get_volume(SoundManager.Bus.SFX))
	config.set_value("audio","bgm",SoundManager.get_volume(SoundManager.Bus.BGM))
	
	config.save(CONFIG_PATH)

func load_config() ->void:
	var config:=ConfigFile.new()
	config.load(CONFIG_PATH)
	
	SoundManager.set_volume(
		SoundManager.Bus.MASTER,
		config.get_value("audio","master",0.5)
	)
	SoundManager.set_volume(
		SoundManager.Bus.SFX,
		config.get_value("audio","sfx",0.5)
	)
	SoundManager.set_volume(
		SoundManager.Bus.BGM,
		config.get_value("audio","bgm",0.5)
	)
	
func shake_camera(amount:float) ->void:
	camera_should_shake.emit(amount)
