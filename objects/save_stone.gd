extends Interactable

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func interact() ->void:
	super() #super中有定义发出信号
	animation_player.play("activited")
	Game.save_game()
