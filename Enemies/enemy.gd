class_name Enemy
extends CharacterBody2D

enum Direction{
	LEFT=-1,
	RIGHT=1,
}

signal died

@onready var graqphics: Node2D = $Graqphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine

@export var max_speed :float=200
@export var acceleration:float=max_speed/0.3
@export var knock_back_velocity:float=300
var default_gravity :=ProjectSettings.get("physics/2d/default_gravity") as float
const normal_hit_damage :int=1
const critical_hit_damage:int=2

var pending_damage:Damage

@export var direction:=Direction.LEFT:
	set(v):
		direction=v
		if not is_node_ready():
			await ready
		graqphics.scale.x=-direction

func _ready()->void:
	add_to_group("enemies")

func move(speed:float,delta:float) ->void:
	velocity.x=move_toward(velocity.x,direction*speed,acceleration*delta)
	velocity.y+=default_gravity*delta

	move_and_slide()


func die() ->void:
	died.emit()
	queue_free()

func damage_count(is_critical_hit:bool) ->int:
	return critical_hit_damage if is_critical_hit else normal_hit_damage
