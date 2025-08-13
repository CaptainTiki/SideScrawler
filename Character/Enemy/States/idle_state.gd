extends EnemyState
class_name EnemyIdleState

@export var min_wait: float = 1.0
@export var max_wait: float = 2.0
@export var wander_state: EnemyState
@export var chase_state: EnemyState
@export var player_ray: RayCast3D

var timer: Timer

func enter() -> void:
	enemy.velocity = Vector3.ZERO
	if timer:
		timer.queue_free()
	timer = Timer.new()
	timer.wait_time = randf_range(min_wait, max_wait)
	timer.one_shot = true
	timer.timeout.connect(func(): state_component.transition_to(wander_state))
	add_child(timer)
	timer.start()

func physics_update(_delta: float) -> void:
	if player_ray and player_ray.is_colliding() and player_ray.get_collider() is Player:
		state_component.transition_to(chase_state)

func exit() -> void:
	if timer:
		timer.queue_free()
