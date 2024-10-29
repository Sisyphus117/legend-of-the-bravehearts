class_name Player
extends CharacterBody2D

enum Direction{
	LEFT=-1,
	RIGHT=1,
}

enum State{
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP,
	ATK_1,
	ATK_2,
	ATK_3,
	HURT,
	DYING,
	SLIDE_1,
	SLIDE_2,
	SLIDE_3,
}
const GROUND_STATES=[State.IDLE,State.RUNNING,State.LANDING,
			State.SLIDE_1,State.SLIDE_2,State.SLIDE_3]
const ATK_STATES=[State.ATK_1,State.ATK_2,State.ATK_3]
const RUN_SPEED :=180.0
const WALL_JUMP_VELOCITY:=Vector2(300,-320)
const FLOOR_ACCELERATION :=RUN_SPEED/0.3
const AIR_ACCELERATION :=RUN_SPEED/0.1
const JUMP_VELOCITY :=-350.0
const normal_hit_damage :int=1
const critical_hit_damage:int=2
const SLIDE_DURATION:float=0.5
const SLIDE_SPEED:=150.0
const LANDING_HEIGHT:=90.0
const SLIDING_ENERGY:=4.0
var default_gravity :=ProjectSettings.get("physics/2d/default_gravity") as float
var is_first_tick:=false
var is_combo_requested:=false
var attack_count:=0
var pending_damage:Damage
var fall_from_y:float
var interacting_with:Interactable

func _ready() -> void:
	stand(default_gravity,0.01)
	#stats.max_health=5
	#stats.health=stats.max_health
	pass

@export var can_combo :=false
@export var knock_back_velocity:float=300
@export var direction :=Direction.RIGHT:
	set(v):
		if not is_node_ready():
			await ready
		graphics.scale.x=v
		direction=v
	

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $coyoteTimer
@onready var jump_request_timer: Timer = $jumpRequestTimer
@onready var graphics: Node2D = $Graphics
@onready var hand_checker: RayCast2D = $Graphics/handChecker
@onready var foot_checker: RayCast2D = $Graphics/footChecker
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = Game.player_stats
@onready var invincible_timer: Timer = $invincibleTimer
@onready var slide_request_timer: Timer = $slideRequestTimer
@onready var interaction_icon: AnimatedSprite2D = $InteractionIcon
@onready var game_over_screen: Control = $CanvasLayer/GameOverScreen
@onready var pause_screen: Control = $CanvasLayer/PauseScreen
@onready var virtual_joypad: Control = $CanvasLayer/VirtualJoypad

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_released("jump") and velocity.y<JUMP_VELOCITY/10:
		velocity.y=JUMP_VELOCITY/10
	if event.is_action_pressed("attack") and can_combo:
		is_combo_requested=true
	if event.is_action_pressed("slide") and stats.energy>=SLIDING_ENERGY:
		slide_request_timer.start()
	if event.is_action_pressed("interacting") and interacting_with!=null and state_machine.current_state!=State.DYING:
		interacting_with.interact()
	if event.is_action_pressed("pause"):
		pause_screen.show_pause()

	

func tick_physics(state:State,delta:float) -> void:
	interaction_icon.visible= interacting_with!=null and state_machine.current_state!=State.DYING
	if invincible_timer.time_left>0:
		graphics.modulate.a=sin(Time.get_ticks_msec()/30)*0.4+0.6
	else :
		graphics.modulate.a=1
	match state:
		State.IDLE:
			move(delta,default_gravity)
		State.RUNNING:
			move(delta,default_gravity)
		State.JUMP:
			move(delta,0.0 if is_first_tick else default_gravity)
			is_first_tick=false
		State.FALL:
			move(delta,default_gravity)
		State.LANDING:
			stand(delta,default_gravity)
		State.WALL_SLIDING:
			move(delta,default_gravity/7)
			direction=Direction.LEFT if get_wall_normal().x<0 else Direction.RIGHT
		State.WALL_JUMP:
			if state_machine.current_state<0.1:
				stand(delta,0.0 if is_first_tick else default_gravity)
			else:
				move(delta,0.0 if is_first_tick else default_gravity)
				is_first_tick=false
		State.ATK_1,State.ATK_2,State.ATK_3:
			stand(delta,default_gravity)
		State.HURT,State.DYING:
			stand(delta,default_gravity)
		State.SLIDE_1,State.SLIDE_2:
			slide(delta)
		State.SLIDE_3:
			stand(delta,default_gravity)

func slide(delta:float)->void:
	velocity.x=direction*SLIDE_SPEED
	velocity.y+=default_gravity*delta
	move_and_slide()
	

func move(delta:float,gravity:float)->void:
	var movement:=Input.get_axis("move_left","move_right")
	var acceleration:=FLOOR_ACCELERATION if is_on_floor() or is_on_wall() else AIR_ACCELERATION
	velocity.x=move_toward(velocity.x,movement*RUN_SPEED,acceleration*delta)
	velocity.y+=gravity*delta

	if not is_zero_approx(movement):
		direction=Direction.LEFT if movement<0 else Direction.RIGHT
	move_and_slide()
	
func stand(delta:float,gravity:float) ->void:
	var acceleration:=FLOOR_ACCELERATION if is_on_floor() or is_on_wall() else AIR_ACCELERATION
	velocity.x=move_toward(velocity.x,0.0,acceleration*delta)
	velocity.y+=gravity*delta
	var movement:=Input.get_axis("move_left","move_right")
	if not is_zero_approx(movement):
		direction=Direction.LEFT if movement<0 else Direction.RIGHT
	move_and_slide()
	

func can_wall_slide() ->bool:
	return is_on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding()


func get_next_state(state:State) ->int:
	if pending_damage:
		if stats.health-pending_damage.amount<=0:
			return State.DYING
		return State.HURT
	if state==State.DYING:
		return StateMachine.STAY_CURRENT_STATE
	var can_jump=is_on_floor() or coyote_timer.time_left >0
	var should_jump:=can_jump and jump_request_timer.time_left >0
	#
	var movement:=Input.get_axis("move_left","move_right")
	var is_still=is_zero_approx(movement) and is_zero_approx(velocity.x)
	match state:
		State.IDLE:
			if should_jump:
				return State.JUMP
			if not is_on_floor():
				return State.FALL
			if  not slide_request_timer.is_stopped():
				return State.SLIDE_1
			if not is_still:
				return State.RUNNING
			if Input.is_action_just_pressed("attack") :
				return State.ATK_1
		State.RUNNING:
			#if is_on_wall():
				#return State.IDLE
			if should_jump:
				return State.JUMP
			if not is_on_floor() and not is_on_wall():
				return State.FALL
			if not slide_request_timer.is_stopped() :
				return State.SLIDE_1
			if is_still:
				return State.IDLE
			if Input.is_action_just_pressed("attack") :
				return State.ATK_1
		State.JUMP:
			if can_wall_slide() :
				return State.WALL_SLIDING	
			if velocity.y> 0 :
				return State.FALL
			if Input.is_action_just_pressed("attack") :
				return State.ATK_1
		State.FALL:
			if can_wall_slide() :
				return State.WALL_SLIDING
			if is_on_floor():
				return State.LANDING if global_position.y-fall_from_y>=LANDING_HEIGHT else State.IDLE
			if Input.is_action_just_pressed("attack") :
				return State.ATK_1
		State.LANDING:
			if not is_on_floor():
				return State.FALL
			if not animation_player.is_playing():
				return State.IDLE
			if Input.is_action_just_pressed("attack") :
				return State.ATK_1
		State.WALL_SLIDING:
			if jump_request_timer.time_left>0 and state_machine.state_time>0.05:
				return State.WALL_JUMP
			if is_on_floor() :
				return State.IDLE
			elif not is_on_wall():
				return State.FALL
		State.WALL_JUMP:
			if can_wall_slide() and not is_first_tick:
				return State.WALL_SLIDING	
			if velocity.y> 0 :
				return State.FALL
			if Input.is_action_just_pressed("attack") :
				return State.ATK_1
		State.ATK_1:
			if not animation_player.is_playing():
				if is_combo_requested:
					return State.ATK_2
				return State.IDLE if is_on_floor() else State.FALL
		State.ATK_2:
			if not animation_player.is_playing():
				if is_combo_requested:
					return State.ATK_3
				return State.IDLE if is_on_floor() else State.FALL
		State.ATK_3:
			if not animation_player.is_playing():
				return State.IDLE if is_on_floor() else State.FALL
		State.HURT:
			if not animation_player.is_playing():
				return State.IDLE
		State.SLIDE_1:
			if not animation_player.is_playing():
				return State.SLIDE_2
		State.SLIDE_3:
			if not animation_player.is_playing():
				return State.IDLE
		State.SLIDE_2:
			if state_machine.state_time>SLIDE_DURATION or is_on_wall():
				return State.SLIDE_3
	return StateMachine.STAY_CURRENT_STATE


func transition_state(from:State,to:State) ->void:
	print("[%s] %s => %s" %[
		Engine.get_physics_frames(),
		State.keys()[from] if from!=-1 else "<start>",
		State.keys()[to],
	])
	if from not in GROUND_STATES and to in GROUND_STATES:
		coyote_timer.stop()
	match to:
		State.IDLE:
			animation_player.play("idle")
		State.RUNNING:
			animation_player.play("running")
		State.JUMP:
			animation_player.play("jump")
			SoundManager.play_sfx("Jump")
			velocity.y=JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()
			is_first_tick=true
		State.FALL:
			animation_player.play("fall")
			if from not in ATK_STATES:
				fall_from_y=global_position.y
			if from in GROUND_STATES:
				coyote_timer.start()
		State.LANDING:
			animation_player.play("landing")
		State.WALL_SLIDING:
			animation_player.play("wall_sliding")
		State.WALL_JUMP:
			animation_player.play("Jump")
			SoundManager.play_sfx("jump")
			velocity=WALL_JUMP_VELOCITY
			velocity.x*=get_wall_normal().x
			jump_request_timer.stop()
			is_first_tick=true
		State.ATK_1:
			slide_request_timer.stop()
			attack_count=1
			SoundManager.play_sfx("Attack")
			animation_player.play("attack_1")
			attack_count=0
		State.ATK_2:
			is_combo_requested=false
			attack_count=2
			SoundManager.play_sfx("Attack")
			animation_player.play("attack_2")
			attack_count=0
		State.ATK_3:
			is_combo_requested=false
			attack_count=3
			SoundManager.play_sfx("AttackCritical")
			animation_player.play("attack_3")
			attack_count=0
		State.HURT:
			Game.shake_camera(4)
			SoundManager.play_sfx("Hurt")
			animation_player.play("hurt")
			stats.health-=pending_damage.amount
			var dir:=pending_damage.source.global_position.direction_to(global_position)
			velocity+=knock_back_velocity*dir
			pending_damage=null
			invincible_timer.start()
		State.DYING:
			Game.shake_camera(7)
			SoundManager.play_sfx("Hurt")
			invincible_timer.stop()
			var dir:=pending_damage.source.global_position.direction_to(global_position)
			velocity+=knock_back_velocity*dir*5
			pending_damage=null
			stats.health=0	
			animation_player.play("die")
		State.SLIDE_1:
			SoundManager.play_sfx("Sliding")
			stats.energy-=SLIDING_ENERGY
			animation_player.play("slide_start")
		State.SLIDE_2:
			animation_player.play("sliding_loop")
		State.SLIDE_3:
			animation_player.play("slide_end")
	if to==State.WALL_JUMP:
		Engine.time_scale=0.5
	if from==State.WALL_JUMP:
		Engine.time_scale=1
	if to==State.HURT:
		Engine.time_scale=0.7
	if from==State.HURT:
		Engine.time_scale=1
	if to==State.DYING:
		Engine.time_scale=0.3
	
func damage_count() ->int:
	return critical_hit_damage if attack_count==3 else normal_hit_damage


func die() ->void:
	game_over_screen.show_game_over()
	Engine.time_scale=1

func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	if invincible_timer.time_left>0:
		return 
	pending_damage=Damage.new()
	pending_damage.amount=hitbox.owner.damage_count(false)
	pending_damage.source=hitbox.owner
	


func _on_hitbox_hit(Hurtbox: Variant) -> void:
	Engine.time_scale=0.01
	Game.shake_camera(2)
	await get_tree().create_timer(0.15,true,false,true).timeout
	Engine.time_scale=1
