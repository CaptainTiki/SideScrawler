extends Node3D

@onready var smoke_balls: GPUParticles3D = $SmokeBalls
@onready var streaks: GPUParticles3D = $Streaks
@onready var animation_player: AnimationPlayer = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.play("explosion")
	await animation_player.animation_finished
	queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
