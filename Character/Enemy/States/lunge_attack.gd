extends EnemyState
class_name LungeAttackState

@export var windup_time := 0.15
@export var lunge_speed_x := 7.0
@export var lunge_speed_y := 6.0
@export var keep_push_x := 0.4        
@export var cooldown := 0.8
@export var next_state: EnemyState     
@export var player_ray: RayCast3D  

var player: Player
var _t := 0.0
var _launched := false
var _dir_sign := 1
var _cooldown_until := 0.0

func enter() -> void:
	_t = 0.0
	_launched = false
	player = null
	enemy.play_anim("Walk")

	# face player if we can see them
	if player_ray and player_ray.is_colliding():
		var c := player_ray.get_collider()
		if c is Player:
			player = c

	if player:
		var to_p := player.global_transform.origin - enemy.global_transform.origin
		_dir_sign = 1 if to_p.x >= 0.0 else -1
		enemy.set_facing(_dir_sign)

	# brief windup: stop sliding before jump
	enemy.velocity.x = 0.0

func physics_update(delta: float) -> void:
	_t += delta

	# launch after windup
	if not _launched and _t >= windup_time:
		_launched = true
		_cooldown_until = Time.get_ticks_msec() * 0.001 + cooldown
		# lunge up + forward
		enemy.velocity.x = _dir_sign * lunge_speed_x
		enemy.velocity.y = lunge_speed_y

	# gentle steering in the air
	if _launched and not enemy.is_on_floor():
		var target_vx := _dir_sign * keep_push_x
		enemy.velocity.x = move_toward(enemy.velocity.x, target_vx, 10.0 * delta)

	enemy.slide_with_gravity(delta)

	# transition back to chase on landing
	if _launched and enemy.is_on_floor():
		state_component.transition_to(next_state)

func on_cooldown() -> bool:
	return Time.get_ticks_msec() * 0.001 < _cooldown_until
