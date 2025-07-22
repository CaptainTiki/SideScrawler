extends Node3D

# Attach this script to your Player node to debug muzzle direction
@export var debug_enabled: bool = true
@export var line_length: float = 3.0
@export var line_color: Color = Color.RED

@export var player : Player
@export var muzzle : Node3D

func _ready():
	if debug_enabled:
		print("Muzzle Debug Active - showing firing directions")

func _process(delta):
	if debug_enabled and muzzle:
		_draw_muzzle_direction()
		_print_muzzle_info()

func _draw_muzzle_direction():
	# Clear any existing debug lines
	# We'll use DebugDraw3D or simple sphere/cube visualization
	
	# Get muzzle world position and direction
	var muzzle_pos = muzzle.global_position
	var muzzle_forward = muzzle.global_transform.basis.x  # Assuming +X is forward
	var end_pos = muzzle_pos + (muzzle_forward * line_length)
	
	# For now, just print the direction - we can add visual lines later
	pass

func _print_muzzle_info():
	if muzzle and Input.is_action_just_pressed("Shoot_Primary"):
		var muzzle_pos = muzzle.global_position
		var muzzle_transform = muzzle.global_transform
		
		print("=== MUZZLE DEBUG ===")
		print("Position: ", muzzle_pos)
		print("Forward (+X): ", muzzle_transform.basis.x)
		print("Up (+Y): ", muzzle_transform.basis.y)  
		print("Right (+Z): ", muzzle_transform.basis.z)
		print("Player State - Moving: %s, AimUp: %s, Crouching: %s" % [player.is_moving, player.is_aim_up, player.is_crouching])
		print("Player Facing Right: ", player.facing_right)
		print("===================")

# Simple visual debug - spawn a small red cube at the end point
func _spawn_debug_marker():
	var muzzle_pos = muzzle.global_position
	var muzzle_forward = muzzle.global_transform.basis.x
	var end_pos = muzzle_pos + (muzzle_forward * line_length)
	
	# Create a small red cube to show where projectile would go
	var debug_cube = MeshInstance3D.new()
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(0.1, 0.1, 0.1)
	debug_cube.mesh = cube_mesh
	
	# Red material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	debug_cube.material_override = material
	
	# Position it
	debug_cube.global_position = end_pos
	get_tree().current_scene.add_child(debug_cube)
	
	# Remove after 2 seconds
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): debug_cube.queue_free())
	debug_cube.add_child(timer)
	timer.start()
