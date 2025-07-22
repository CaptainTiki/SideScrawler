extends AnimationTree

@export var player: Player
@onready var rotation_handle = player.get_node("RotationHandle")
@onready var state_machine = get("parameters/playback")

func _ready():
	# Connect to player signals
	player.grounded_changed.connect(_on_grounded_changed)
	player.movement_changed.connect(_on_movement_changed)
	player.direction_changed.connect(_on_direction_changed)
	player.aim_up_changed.connect(_on_aim_up_changed)
	player.crouch_changed.connect(_on_crouch_changed)
	player.idle_activated.connect(_on_idle_activated)

func _on_grounded_changed(grounded: bool):
	# Only act when leaving the ground (going into air)
	if not grounded:
		state_machine.travel("Jump")
	elif grounded:
		if player.is_moving:
			state_machine.travel("Run")

func _on_movement_changed(moving: bool):
	# Only travel to Run when starting to move
	if moving and player.is_grounded:
		state_machine.travel("Run")
	# When stopping movement, let idle_activated handle going to Idle

func _on_aim_up_changed(aiming_up: bool):
	# Only travel to AimUP when starting to aim up
	if aiming_up:
		state_machine.travel("AimUP")
	# When stopping aim up, let idle_activated handle going to Idle

func _on_crouch_changed(crouching: bool):
	# Only travel to Crouch when starting to crouch
	if crouching:
		state_machine.travel("Crouch")
	# When stopping crouch, let idle_activated handle going to Idle

func _on_idle_activated():
	# Always travel to Idle when this signal fires
	state_machine.travel("Idle")

func _on_direction_changed(facing_right: bool):
	# Handle character flipping
	_update_character_flip(facing_right)

func _update_character_flip(facing_right: bool):
	# Flip the character by rotating the rotation handle
	if facing_right:
		rotation_handle.rotation.y = 0
	else:
		rotation_handle.rotation.y = PI
