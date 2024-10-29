class_name StateMachine
extends Node

var state_time :float

const STAY_CURRENT_STATE:=-1

var current_state :int=-1:
	set(v):
		owner.transition_state(current_state,v)
		current_state=v
		state_time=0

func _ready() -> void :
	await owner.ready
	current_state=0

func _physics_process(delta: float) -> void:
	while true:
		var next=owner.get_next_state(current_state) as int
		if next==STAY_CURRENT_STATE:
			break
		else:
			current_state=next
		
	owner.tick_physics(current_state,delta)
	
	state_time+=delta
	
