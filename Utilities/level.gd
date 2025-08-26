# Level.gd
extends Node3D
class_name Level

@export var player: Player
@export var camera: SideScrollerCamera

@onready var level_generator: Node3D = $Level_Generator

func _ready() -> void:
	level_generator.connect("generation_finished", _on_generation_finished)
	level_generator.generate()

func _on_generation_finished(spawn_xform: Transform3D) -> void:
	# Move player to spawn transform (position + facing from spawn marker)
	player.global_transform = spawn_xform

	# Nudge up a hair if needed to avoid embedding (tweak if your tiles are exact)
	player.global_position.y += 0.05

	# Hook camera target (adjust to your camera API)
	camera.set_node_to_track(player)
