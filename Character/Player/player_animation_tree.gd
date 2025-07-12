# player_animation_tree.gd
extends AnimationTree

@onready var playback: AnimationNodeStateMachinePlayback = get("parameters/playback")
@export var player: Player

func _ready() -> void:
	# Connect to the player's state_changed signal.
	player.state_changed.connect(_on_state_changed)

func _on_state_changed(new_state: String) -> void:
	# Get the current animation node.
	var current: String = playback.get_current_node()
	
	# Handle special transitions where applicable.
	if current == "Idle" and new_state == "AimUP":
		playback.travel("Idle_To_AimUP")
	elif current == "AimUP" and new_state == "Idle":
		playback.travel("AimUP_To_Idle")  # If you don't have an "AimUP_To_Idle" state, change this to playback.travel("Idle")
	elif current == "Idle" and new_state == "Crouch":
		playback.travel("Idle_To_Crouch")
	elif current == "Crouch" and new_state == "Idle":
		playback.travel("Crouch_To_Idle")
	elif current == "Idle" and new_state == "Run":
		playback.travel("Idle_To_Run")
	elif current == "Run" and new_state == "Idle":
		playback.travel("Run_To_Idle")
	# Add transitions for jump-related states if you have special ones (e.g., from Run to Jump_Start).
	# For now, assuming direct travel for jump/fall/land unless specified.
	else:
		# Default to direct travel to the target state.
		playback.travel(new_state)
