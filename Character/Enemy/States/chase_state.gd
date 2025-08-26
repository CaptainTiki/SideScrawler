# chase_state.gd
extends EnemyState
class_name EnemyChaseState

@export var speed: float = 3.5
@export var accel: float = 18.0
@export var attack_range: float = 1.5
@export var player_ray: RayCast3D
@export var lost_state: EnemyState
@export var attack_state: EnemyState

var player: Player

func enter() -> void:
	player = null  # reacquire cleanly on enter
	enemy.play_anim("Walk")

func physics_update(delta: float) -> void:
	if not _acquire_player():
		state_component.transition_to(lost_state)
		return

	var to_p := player.global_transform.origin - enemy.global_transform.origin
	var dir_sign := 1 if to_p.x >= 0.0 else -1
	enemy.set_facing(dir_sign)

	var dist_x : float = abs(to_p.x)

	# If slime has an attack_state and is close + grounded, lunge
	if attack_state and dist_x <= attack_range and enemy.is_on_floor():
		# If it's the SlimeAttackState, respect its cooldown if exposed:
		if attack_state.has_method("on_cooldown") and attack_state.call("on_cooldown"):
			# still on cooldown → just chase
			pass
		else:
			state_component.transition_to(attack_state)
			return

	# otherwise: run toward player
	var target_vx := dir_sign * speed
	enemy.velocity.x = move_toward(enemy.velocity.x, target_vx, accel * delta)
	enemy.slide_with_gravity(delta)

func _acquire_player() -> bool:
	# Use the ray purely as a LOS gate; do not flip it in code
	if player_ray and player_ray.is_colliding():
		var c := player_ray.get_collider()
		if c is Player:
			player = c
	return player != null and is_instance_valid(player)

func exit() -> void:
	enemy.velocity = Vector3.ZERO
	
