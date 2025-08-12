extends EnemyState
class_name EnemyChaseState

@export var speed: float = 3.0
@export var attack_range: float = 1.5
@export var player_ray_path: NodePath
@export var lost_state: StringName = "IdleState"

var player_ray: RayCast3D
var player: Player
var attack_range_sq: float

func enter() -> void:
    player_ray = enemy.get_node(player_ray_path) as RayCast3D
    attack_range_sq = attack_range * attack_range

func physics_update(_delta: float) -> void:
    if not _acquire_player():
        state_component.transition_to(lost_state)
        return
    var to_player: Vector3 = player.global_position - enemy.global_position
    var dist_sq: float = to_player.length_squared()
    if dist_sq <= attack_range_sq:
        enemy.attack(player)
        return
    var dir: Vector3 = to_player.normalized()
    enemy.velocity.x = dir.x * speed
    enemy.move_and_slide()
    if player_ray:
        var sign_x = dir.x >= 0 ? 1.0 : -1.0
        player_ray.target_position.x = sign_x * abs(player_ray.target_position.x)

func _acquire_player() -> bool:
    if player_ray and player_ray.is_colliding():
        var collider = player_ray.get_collider()
        if collider is Player:
            player = collider
    return player != null and is_instance_valid(player)

func exit() -> void:
    enemy.velocity = Vector3.ZERO
