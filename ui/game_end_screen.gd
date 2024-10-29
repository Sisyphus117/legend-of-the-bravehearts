extends Control

@onready var label: Label = $Label
@onready var tips: Label = $tips

const LINES:=[
	"森林终于恢复了往日的平静",
	"勇者战胜了强大的敌人",
	"从此",
	"野猪公主和勇者",
	"没羞没臊的生活在了一起",
	"但这一切值得吗?",
]

var current_line:=-1
var tween:Tween

func _ready() ->void:
	tips.visible=false
	show_line(0)
	SoundManager.play_bgm(preload("res://assets/bgm/29 15 game over LOOP.mp3"))
	#set_process_input(false) 平时不会出现本界面(不同于game_over一直挂在player

	
func _input(event:InputEvent) ->void:
	get_window().set_input_as_handled()
	if tween.is_running():
		return
	if( event is InputEventKey or
		event is InputEventMouse or 
		event is InputEventJoypadButton
	):
		if event.is_pressed() and not event.is_echo():
			if current_line+1<LINES.size():
				show_line(current_line+1)
			else :
				Game.back_to_title()

func show_line(line:int) ->void:
	tips.visible=false
	current_line=line
	tween=create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	if line>0:
		tween.tween_property(label,"modulate:a",0,1)
	else:
		label.modulate.a=0
	tween.tween_callback(label.set_text.bind(LINES[line]))
	tween.tween_property(label,"modulate:a",1,1)
	await tween.finished
	tips.visible=true	
