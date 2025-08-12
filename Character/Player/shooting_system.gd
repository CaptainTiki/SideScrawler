extends Node
class_name ShootingSystem

# Shooting settings
@export var fire_rate: float = 0.2  # Time between shots
@export var projectile_speed: float = 18.0
@export var projectile_lifetime: float = 2.5
@export var spread_randomness: float = 0.05  # Random spread (0 = perfect accuracy)

@export var projectile_scene: PackedScene
@export var player: Player
@export var muzzle: Node3D

# Internal state
var fire_cooldown: float = 0.0

func _ready():
	pass

func _process(delta):
	# Update cooldown timer
	if fire_cooldown > 0:
		fire_cooldown -= delta
	
	_handle_shooting_input()

func _handle_shooting_input():
	if Input.is_action_pressed("Shoot_Primary") and _can_shoot():
		fire_cooldown = fire_rate
		_handle_shooting()

func _can_shoot() -> bool:
	return fire_cooldown <= 0

func _handle_shooting():
	var animation_tree = player.get_node("PlayerAnimationTree")
	var state_machine = animation_tree.get("parameters/playback")
	var current_state = state_machine.get_current_node()
	
        # Check if we should transition to shoot animation first
        if current_state == "Idle":
                # Travel to shoot animation first, then fire
                state_machine.travel("Shoot")
                # Start the 2 second timer to return to appropriate state
                animation_tree._start_shoot_timer()
                # Wait a brief moment for animation to start, then fire
                await get_tree().create_timer(0.1).timeout
                _fire_projectile()
        else:
                # Fire immediately without animation change (crouch, aim up, jump, run, etc.)
                _fire_projectile()

func _fire_projectile():
	if not projectile_scene or not muzzle:
		print("Missing projectile scene or muzzle!")
		return
	
	# Get spawn position from muzzle
	var spawn_pos = muzzle.global_position
	
	# Calculate base direction
	var direction = _get_projectile_direction()
	
	# Add randomness if enabled
	if spread_randomness > 0:
		direction = _add_spread(direction)
	
	# Create and configure projectile
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	
	# Set projectile position and rotation based on player state
	projectile.global_position = spawn_pos
	
	# Rotate projectile to face travel direction using player state
	if player.is_aim_up:
		# Player is aiming up - rotate projectile to point upward
		projectile.rotation_degrees = Vector3(0, 0, 90)
	elif not player.facing_right:
		# Player facing left - flip projectile to face left
		projectile.rotation_degrees = Vector3(0, 0, 180)
	# Player facing right uses default rotation (0,0,0)
	
	# Set projectile properties
	projectile.setup(direction, projectile_speed, projectile_lifetime)

func _get_projectile_direction() -> Vector3:
	if player.is_aim_up:
		# Shoot straight up
		return Vector3.UP
	elif player.is_crouching:
		# Shoot forward (same as normal, just crouched down)
		return Vector3.RIGHT if player.facing_right else Vector3.LEFT
	else:
		# Normal forward shooting
		return Vector3.RIGHT if player.facing_right else Vector3.LEFT

func _add_spread(base_direction: Vector3) -> Vector3:
	# Add random spread to X and Y
	var spread_x = randf_range(-spread_randomness, spread_randomness)
	var spread_y = randf_range(-spread_randomness, spread_randomness)
	
	var spread_direction = base_direction + Vector3(spread_x, spread_y, 0)
	return spread_direction.normalized()
