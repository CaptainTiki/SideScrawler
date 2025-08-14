extends CharacterBody3D
class_name Enemy

@onready var health_component: HealthComponent = get_node_or_null("HealthComponent")
@onready var state_component: StateComponent = get_node_or_null("StateComponent")
@onready var rotation_handle: Node3D = get_node_or_null("RotationHandle")

func _ready() -> void:
	add_to_group("enemies")
	if health_component:
		health_component.died.connect(_on_died)
	else:
		push_warning("Enemy missing HealthComponent")
	if not state_component:
		push_warning("Enemy missing StateComponent")
	var vis = $VisibleOnScreenEnabler3D
	vis.screen_entered.connect(_enabled_fired)
	vis.screen_exited.connect(_disabled_fired)

func _process(delta: float) -> void:
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

func _on_died() -> void:
        queue_free()

func set_facing_right(facing_right: bool) -> void:
        if rotation_handle:
                rotation_handle.rotation.y = 0 if facing_right else PI
