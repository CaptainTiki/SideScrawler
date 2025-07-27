extends Node3D

@export var INTENSITY: float = .15

func _ready() -> void:
	# Wait one frame to ensure everything is properly set up
	await get_tree().process_frame
	
	# Apply forces to all RigidBody3D children
	for piece in get_children():
		if piece is RigidBody3D:
			# Unfreeze the body so it can move (set to KINEMATICGID mode for full physics)
			piece.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
			piece.freeze = false
			
			# Calculate explosion direction from center
			var explosion_direction = piece.global_position - global_position
			if explosion_direction.length() < 0.1:  # Avoid zero vector
				explosion_direction = Vector3(randf_range(-1, 1), randf_range(0.5, 1), randf_range(-1, 1))
			
			explosion_direction = explosion_direction.normalized()
			
			# Add some randomness
			var random_force = Vector3(
				randf_range(-1, 1),
				randf_range(0.5, 2),  # Always go up a bit
				randf_range(-1, 1)
			)
			
			var final_force = (explosion_direction + random_force) * INTENSITY
			
			# Apply the impulse
			piece.apply_central_impulse(final_force)
	
	# Clean up after 10 seconds
	await get_tree().create_timer(10.0).timeout
	queue_free()

# Quick fix for destructible_object.gd _destroy_object function:
# Add this right at the start of _destroy_object():
# 
# # Immediately disable collision to prevent multiple hits
# for child in get_children():
#     if child is CollisionShape3D:
#         child.disabled = true
#     elif child is Area3D:
#         child.monitoring = false
