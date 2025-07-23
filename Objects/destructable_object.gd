extends StaticBody3D
class_name DestructibleObject

# Destruction effects
@export var destruction_effect: PackedScene  # Spawn this when destroyed
@export var spawn_effect_at_center: bool = true  # Or at hit point

# Visual feedback settings
@export var hit_flash_duration: float = 0.1
@export var hit_flash_color: Color = Color.WHITE

# Component references
@onready var health_component: HealthComponent = $HealthComponent

# Internal
var original_material: Material
var is_destroyed: bool = false

func _ready():
	_setup_health_component()
	_setup_hit_detection()
	_store_original_material()

func _setup_health_component():
	if not health_component:
		print("Warning: DestructibleObject missing HealthComponent!")
		return
	
	# Connect to HealthComponent signals
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)

func _setup_hit_detection():
	# Connect to any Area3D child for hit detection
	for child in get_children():
		if child is Area3D:
			child.body_entered.connect(_on_projectile_hit)
			return
	
	# If no Area3D found, create one
	_create_hit_detection_area()

func _create_hit_detection_area():
	var area = Area3D.new()
	area.name = "HitDetection"
	add_child(area)
	
	# Copy the collision shape from our StaticBody3D
	for child in get_children():
		if child is CollisionShape3D:
			var new_collision = CollisionShape3D.new()
			new_collision.shape = child.shape
			new_collision.transform = child.transform
			area.add_child(new_collision)
			break
	
	area.body_entered.connect(_on_projectile_hit)

func _store_original_material():
	# Store original material for hit flash effect
	var mesh_instance = _find_mesh_instance()
	if mesh_instance and mesh_instance.material_override:
		original_material = mesh_instance.material_override
	elif mesh_instance and mesh_instance.get_surface_override_material(0):
		original_material = mesh_instance.get_surface_override_material(0)

func _find_mesh_instance() -> MeshInstance3D:
	for child in get_children():
		if child is MeshInstance3D:
			return child
	return null

func _on_projectile_hit(body):
	# Check if it's a projectile and we have a health component
	if body is MagicProjectile and health_component and not is_destroyed:
		health_component.take_damage(1)

func _on_damaged(_damage_amount: int, _current_health: int):
	# Visual feedback when taking damage
	_show_hit_flash()

func _on_died():
	# Handle destruction
	_destroy_object()

func _show_hit_flash():
	var mesh_instance = _find_mesh_instance()
	if not mesh_instance:
		return
	
	# Create white flash material
	var flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = hit_flash_color
	flash_material.emission_enabled = true
	flash_material.emission = hit_flash_color
	
	# Apply flash
	mesh_instance.material_override = flash_material
	
	# Return to original after duration
	var timer = Timer.new()
	timer.wait_time = hit_flash_duration
	timer.one_shot = true
	timer.timeout.connect(_restore_original_material)
	add_child(timer)
	timer.start()

func _restore_original_material():
	var mesh_instance = _find_mesh_instance()
	if mesh_instance:
		mesh_instance.material_override = original_material
	
	# Clean up timer
	for child in get_children():
		if child is Timer:
			child.queue_free()
			break

func _destroy_object():
	if is_destroyed:
		return
		
	is_destroyed = true
	print("Object destroyed!")
	
	# Spawn destruction effect if provided
	if destruction_effect:
		_spawn_destruction_effect()
	
	# Remove object
	queue_free()

func _spawn_destruction_effect():
	var effect = destruction_effect.instantiate()
	get_parent().add_child(effect)
	
	# Position the effect
	if spawn_effect_at_center:
		effect.global_position = global_position
	else:
		# Could position at hit point - implement later
		effect.global_position = global_position
