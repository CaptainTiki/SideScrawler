extends Area3D
class_name MagicProjectile

var direction: Vector3
var speed: float
var lifetime: float
var time_alive: float = 0.0

@export var damage: int = 1  # How much damage this projectile deals
@export var impact_effect: PackedScene

func _ready():
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(projectile_direction: Vector3, projectile_speed: float, projectile_lifetime: float):
	direction = projectile_direction.normalized()
	speed = projectile_speed
	lifetime = projectile_lifetime

func _physics_process(delta):
	# Update lifetime
	time_alive += delta
	
	# Destroy after lifetime expires
	if time_alive >= lifetime:
		_destroy_projectile()
	
	# Move projectile
	global_position += direction * speed * delta

func _on_body_entered(body):
	# Don't hit the player who fired this projectile
	if body is Player:
		return
		
	#print("Projectile hit body: ", body.name)
	
	# Try to deal damage to the body
	_deal_damage_to_target(body)
	
	_create_impact_effect()
	_destroy_projectile()

func _on_area_entered(area):
	# Hit an area - try to find the parent object to damage
	var target = area.get_parent()
	
	#print("Projectile hit area: ", area.name, " (parent: ", target.name, ")")
	
	# Try to deal damage to the parent object
	_deal_damage_to_target(target)
	
	_create_impact_effect()
	_destroy_projectile()

func _deal_damage_to_target(target):
	if not target:
		return
		
	# Look for HealthComponent as a direct child
	var health_component = _find_health_component(target)
	
	if health_component:
		#print("Dealing ", damage, " damage to ", target.name, " leaving: ", health_component.current_health)
		health_component.take_damage(damage)
	#else:
		#print("No HealthComponent found on ", target.name)

func _find_health_component(node) -> HealthComponent:
	# Check if the node itself is a HealthComponent
	if node is HealthComponent:
		return node
	
	# Check children for HealthComponent
	for child in node.get_children():
		if child is HealthComponent:
			return child
	
	return null

func _create_impact_effect():
	if not impact_effect:
		return
		
	var effect : Node3D = impact_effect.instantiate()
	await effect.tree_entered
	effect.global_position = global_position
	
	# Orient the explosion so Vector3.UP points opposite to travel direction
	# This makes sparks/debris fly back toward where the projectile came from
	var backward_direction = -direction
	
	# Create a transform where UP (Y-axis) points in the backward direction
	# We'll use the backward direction as the new Y axis
	var new_up = backward_direction
	
	# Create perpendicular vectors for X and Z axes
	var temp_forward = Vector3.FORWARD
	if abs(new_up.dot(temp_forward)) > 0.9:  # If too parallel, use a different reference
		temp_forward = Vector3.RIGHT
	
	var new_right = temp_forward.cross(new_up).normalized()
	var new_forward = new_up.cross(new_right).normalized()
	
	# Build the basis with our new orientation
	effect.basis = Basis(new_right, new_up, new_forward)
	
	get_tree().root.add_child(effect)

func _destroy_projectile():
	queue_free()
