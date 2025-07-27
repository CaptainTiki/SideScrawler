extends Node3D

@export var particles: GPUParticles3D

func _ready() -> void:
	if particles:
		particles.restart()
		
		# Wait for particles to finish, then clean up
		particles.finished.connect(_on_particles_finished)

func _on_particles_finished():
	queue_free()
