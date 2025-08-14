extends EnemyState
class_name EnemyWanderState

@export var speed: float = 2.0
@export var move_time: float = 2.0
@export var chase_state: EnemyState
@export var idle_state: EnemyState
@export var wall_ray: RayCast3D
@export var floor_ray: RayCast3D
@export var player_ray: RayCast3D

var direction: float = 1.0
var timer: Timer
var wall_target_x: float
var floor_target_x: float
var floor_position_x: float
var floor_target_y: float
var player_target_x: float

func enter() -> void:
    direction = randf() < 0.5 ? -1.0 : 1.0
    wall_target_x = abs(wall_ray.target_position.x)
    floor_target_x = abs(floor_ray.target_position.x)
    floor_position_x = abs(floor_ray.position.x)
    floor_target_y = floor_ray.target_position.y
    if player_ray:
        player_target_x = abs(player_ray.target_position.x)
    if timer:
        timer.queue_free()
    timer = Timer.new()
    timer.wait_time = move_time
    timer.one_shot = true
    timer.timeout.connect(func(): state_component.transition_to(idle_state))
    add_child(timer)
    timer.start()
    _update_rays()
    enemy.set_facing_right(direction > 0)

func _update_rays() -> void:
    wall_ray.target_position.x = direction * wall_target_x
    floor_ray.position.x = direction * floor_position_x
    floor_ray.target_position.x = direction * floor_target_x
    floor_ray.target_position.y = floor_target_y
    if player_ray:
        player_ray.target_position.x = direction * player_target_x

func physics_update(_delta: float) -> void:
    _update_rays()
    if player_ray and player_ray.is_colliding() and player_ray.get_collider() is Player:
        state_component.transition_to(chase_state)
        return
    if wall_ray.is_colliding() or not floor_ray.is_colliding():
        direction *= -1.0
        _update_rays()
        enemy.set_facing_right(direction > 0)
    enemy.velocity.x = direction * speed
    enemy.move_and_slide()

func exit() -> void:
    enemy.velocity = Vector3.ZERO
    if timer:
        timer.queue_free()
