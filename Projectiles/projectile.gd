extends Area3D
class_name MagicProjectile

var direction: Vector3
var speed: float
var lifetime: float
var time_alive: float = 0.0

@export var damage: int = 1  # How much damage this projectile deals

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
		
	print("Projectile hit body: ", body.name)
	
	# Try to deal damage to the body
	_deal_damage_to_target(body)
	
	_create_impact_effect()
	_destroy_projectile()

func _on_area_entered(area):
	# Hit an area - try to find the parent object to damage
	var target = area.get_parent()
	
	print("Projectile hit area: ", area.name, " (parent: ", target.name, ")")
	
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
		print("Dealing ", damage, " damage to ", target.name)
		health_component.take_damage(damage)
	else:
		print("No HealthComponent found on ", target.name)

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
	# TODO: Add particle effect here
	print("BOOM! Impact effect at: ", global_position)

func _destroy_projectile():
	queue_free()
