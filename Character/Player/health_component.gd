extends Node3D
class_name HealthComponent

# Health settings
@export var max_health: int = 1
@export var current_health: int = 1

# Damage settings
@export var invincibility_time: float = 0.0  # Time between damage instances

# Signals
signal health_changed(old_health: int, new_health: int)
signal damaged(damage_amount: int, current_health: int)
signal healed(heal_amount: int, current_health: int)
signal died()
signal invincibility_started()
signal invincibility_ended()

# Internal state
var is_invincible: bool = false
var is_dead: bool = false

func _ready():
	current_health = max_health

func take_damage(amount: int) -> bool:
	# Return false if damage was blocked
	if is_dead or is_invincible or amount <= 0:
		return false
	
	var old_health = current_health
	current_health = max(0, current_health - amount)
	
	# Emit signals
	health_changed.emit(old_health, current_health)
	damaged.emit(amount, current_health)
	
	print("HealthComponent: Took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	# Check for death
	if current_health <= 0 and not is_dead:
		_handle_death()
	
	# Start invincibility if enabled
	if invincibility_time > 0:
		_start_invincibility()
	
	return true

func heal(amount: int) -> bool:
	# Return false if healing was blocked
	if is_dead or amount <= 0:
		return false
	
	var old_health = current_health
	
	current_health = min(max_health, current_health + amount)
	
	# Only emit if health actually changed
	if current_health != old_health:
		health_changed.emit(old_health, current_health)
		healed.emit(amount, current_health)
		print("HealthComponent: Healed ", amount, ". Health: ", current_health, "/", max_health)
		return true
	
	return false

func set_health(value: int):
	var old_health = current_health
	current_health = clamp(value, 0, max_health)
	
	if current_health != old_health:
		health_changed.emit(old_health, current_health)
		
		if current_health <= 0 and not is_dead:
			_handle_death()

func _handle_death():
	if is_dead:
		return
		
	is_dead = true
	print("HealthComponent: Died!")
	died.emit()

func _start_invincibility():
	if is_invincible:
		return
		
	is_invincible = true
	invincibility_started.emit()
	
	# Create timer for invincibility
	var timer = Timer.new()
	timer.wait_time = invincibility_time
	timer.one_shot = true
	timer.timeout.connect(_end_invincibility)
	add_child(timer)
	timer.start()

func _end_invincibility():
	is_invincible = false
	invincibility_ended.emit()
	
	# Clean up timer
	for child in get_children():
		if child is Timer:
			child.queue_free()
			break
