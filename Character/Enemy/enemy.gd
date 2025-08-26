extends CharacterBody3D
class_name Enemy

@export var touch_damage: int = 1

@onready var health_component: HealthComponent = get_node_or_null("HealthComponent")
@onready var state_component: StateComponent = get_node_or_null("StateComponent")
@onready var rotation_handle: Node3D = get_node_or_null("RotationHandle")
@onready var touch_damage_area: Area3D = $TouchDamageArea

@export var animation_player: AnimationPlayer

var max_fall_speed: float = 9.8
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	add_to_group("enemies")
	health_component.died.connect(_on_died)
	touch_damage_area.body_entered.connect(_on_touch_body_entered)
	$VisibleOnScreenEnabler3D.screen_entered.connect(_enabled_fired)
	$VisibleOnScreenEnabler3D.screen_exited.connect(_disabled_fired)

func _process(_delta: float) -> void:
	pass

func _enabled_fired():
	set_physics_process(true)
	pass

func _disabled_fired():
	pass

func take_damage(amount: int) -> void:
	if health_component:
		health_component.take_damage(amount)

func attack(target: Player) -> void:
		var target_health: HealthComponent = target.get_node_or_null("HealthComponent")
		if target_health:
				target_health.take_damage(1)

func play_anim(name: String, custom_blend := -1.0, custom_speed := 1.0, from_end := false) -> void:
	if animation_player:
		animation_player.play(name, custom_blend, custom_speed, from_end)

func stop_anim() -> void:
	if animation_player:
		animation_player.stop()

func _on_touch_body_entered(body: Node) -> void:
	# Either check the class or a group; group is flexible:
	if body.is_in_group("player") or body is Player:
		var hc := body.get_node_or_null("HealthComponent") as HealthComponent
		if hc and not hc.is_invincible:
			hc.take_damage(touch_damage)
			# Knockback — make sure Player has a velocity we can change
			if "velocity" in body:
				var dir : float = sign(body.global_transform.origin.x - global_transform.origin.x)
				# dir > 0 means player is to the right of enemy, so push right
				body.velocity.x = dir * 8.0     # horizontal push strength
				body.velocity.y = 4.0           # small hop up

func _on_died() -> void:
		queue_free()

func set_facing(sign_x: int) -> void:
	rotation_handle.rotation.y = 0.0 if sign_x <= 0 else PI

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		if velocity.y < -max_fall_speed:
			velocity.y = -max_fall_speed
	# Optional: small stick-to-ground when on floor to avoid tiny hops
	elif velocity.y < 0.0:
		velocity.y = 0.0

func slide_with_gravity(delta: float) -> void:
	apply_gravity(delta)
	move_and_slide()
