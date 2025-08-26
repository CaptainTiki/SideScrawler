extends EnemyState
class_name EnemyWanderState

@export var speed: float = 2.0
@export var move_time: float = 2.0
@export var chase_state: EnemyState
@export var idle_state: EnemyState
@export var wall_ray: RayCast3D
@export var floor_ray: RayCast3D
@export var player_ray: RayCast3D

var direction: int = 1.0
var timer: Timer

func enter() -> void:
	direction = sign(randi())
	if timer:
		timer.queue_free()
	timer = Timer.new()
	timer.wait_time = move_time
	timer.one_shot = true
	timer.timeout.connect(func(): state_component.transition_to(idle_state))
	add_child(timer)
	timer.start()
	enemy.set_facing(direction)
	enemy.play_anim("Walk")

func physics_update(delta: float) -> void:
	#player detection
	if player_ray and player_ray.is_colliding() and player_ray.get_collider() is Player:
		state_component.transition_to(chase_state)
		return
	#wall and floor avoidance
	if wall_ray.is_colliding() or not floor_ray.is_colliding():
		direction *= -1.0
		enemy.set_facing(direction)
	
	#move in the direction we're facing
	enemy.velocity.x = direction * speed
	enemy.slide_with_gravity(delta)

func exit() -> void:
	enemy.velocity = Vector3.ZERO
	if timer:
		timer.queue_free()
