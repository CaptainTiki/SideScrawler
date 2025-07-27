extends Node3D

@onready var debris: GPUParticles3D = $Debris
@onready var smoke: GPUParticles3D = $Smoke
@onready var fire: GPUParticles3D = $Fire
@onready var explosion_sound: AudioStreamPlayer3D = $ExplosionSound

var debris_finished = false
var smoke_finished = false
var fire_finished = false
var audio_finished = false

func _ready():
	# Connect to all finished signals
	debris.finished.connect(_on_debris_finished)
	smoke.finished.connect(_on_smoke_finished)
	fire.finished.connect(_on_fire_finished)
	explosion_sound.finished.connect(_on_audio_finished)
	
	# Start all effects
	debris.emitting = true
	smoke.emitting = true
	fire.emitting = true
	explosion_sound.play()

func _on_debris_finished():
	debris_finished = true
	_check_cleanup()

func _on_smoke_finished():
	smoke_finished = true
	_check_cleanup()

func _on_fire_finished():
	fire_finished = true
	_check_cleanup()

func _on_audio_finished():
	audio_finished = true
	_check_cleanup()

func _check_cleanup():
	# Only clean up when ALL effects are done
	if debris_finished and smoke_finished and fire_finished and audio_finished:
		queue_free()
