extends Enemy
enum State{
	IDLE,
	WALK,
	RUN,
	HURT,
	DYING,
}

@onready var boar: CharacterBody2D = $"."
@onready var wall_checker: RayCast2D = $Graqphics/WallChecker
@onready var player_checker: RayCast2D = $Graqphics/PlayerChecker
@onready var floor_checker: RayCast2D = $Graqphics/FloorChecker
@onready var calm_down_timer: Timer = $calmDownTimer
@onready var stats: Stats = $Stats

func can_see_player() ->bool:
	return player_checker.get_collider() is Player 
func tick_physics(state:State,delta:float) -> void:
	match state:
		State.IDLE:
			move(0.0,delta)
		State.RUN:
			move(max_speed,delta)
			if can_see_player():
				calm_down_timer.start()
				#print("restart!")
		State.WALK:
			move(max_speed/3.5,delta)
		State.HURT,State.DYING:
			move(0.0,delta)

func get_next_state(state:State) ->int:
	if stats.health==0:
		return StateMachine.STAY_CURRENT_STATE if state==State.DYING else State.DYING
	if pending_damage:
		return State.HURT

	match state:
		State.IDLE:
			if can_see_player():
				return State.RUN
			if state_machine.state_time>2:
				if not floor_checker.is_colliding():
					wall_checker.force_raycast_update()
					direction*=-1
				return State.WALK
		State.RUN:
			if can_see_player():
				return StateMachine.STAY_CURRENT_STATE
			#if not floor_checker.is_colliding() or wall_checker.is_colliding():
				#return State.IDLE
			if calm_down_timer.is_stopped():
				return State.WALK
			if wall_checker.is_colliding():
				wall_checker.force_raycast_update()
				direction*=-1
				velocity.x/=2
		State.WALK:
			if can_see_player():
				return State.RUN
			if wall_checker.is_colliding():
				wall_checker.force_raycast_update()
				direction*=-1
			if not floor_checker.is_colliding() :
				return State.IDLE
		State.HURT:
			if not animation_player.is_playing():
				return State.RUN
	return StateMachine.STAY_CURRENT_STATE

func transition_state(from:State,to:State) ->void:
	match to:
		State.IDLE:
			animation_player.play("idle")
		State.RUN:
			animation_player.play("run")
		State.WALK:
			animation_player.play("walk")
		State.HURT:
			SoundManager.play_sfx("BoarHurt")
			animation_player.play("hurt")
			stats.health-=pending_damage.amount
			var dir:=pending_damage.source.global_position.direction_to(global_position)
			velocity+=knock_back_velocity*dir
			direction=Direction.LEFT if dir.x>0 else  Direction.RIGHT
			pending_damage=null
		State.DYING:
			SoundManager.play_sfx("BoarHurt")
			animation_player.play("die")



func _on_hurtbox_hurt(hitbox:Hitbox ) -> void:
	pending_damage=Damage.new()
	pending_damage.amount=hitbox.owner.damage_count()
	pending_damage.source=hitbox.owner
	
