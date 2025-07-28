extends AnimationTree

@export var player: Player
@onready var rotation_handle = player.get_node("RotationHandle")
@onready var state_machine = get("parameters/playback")

# Shooting animation timer
var shoot_timer: Timer
@export var shoot_animation_duration: float = 2.0

func _ready():
	# Connect to player signals
	player.grounded_changed.connect(_on_grounded_changed)
	player.movement_changed.connect(_on_movement_changed)
	player.direction_changed.connect(_on_direction_changed)
	player.aim_up_changed.connect(_on_aim_up_changed)
	player.crouch_changed.connect(_on_crouch_changed)
	player.idle_activated.connect(_on_idle_activated)
	
	# Create and setup shoot timer
	shoot_timer = Timer.new()
	shoot_timer.wait_time = shoot_animation_duration
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)

# Called by shooting system when we transition to shoot animation
func _start_shoot_timer():
	shoot_timer.start()

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
	# Don't go to Idle if we're currently in shoot animation and timer is running
	if shoot_timer.time_left > 0:
		return
	
	# Always travel to Idle when this signal fires
	state_machine.travel("Idle")

func _on_shoot_timer_timeout():
	# Check conditions before going back to appropriate state
	if _should_return_to_idle():
		state_machine.travel("Idle")
	elif player.is_moving and player.is_grounded:
		state_machine.travel("Run")
	# If none of the above, stay in current state

func _should_return_to_idle() -> bool:
	# Only return to Idle if player is in a valid idle state:
	# - On the ground
	# - Not moving
	# - Not aiming up
	# - Not crouching
	# - Not currently shooting (check if shoot input is still held)
	return (player.is_grounded and 
			not player.is_moving and 
			not player.is_aim_up and 
			not player.is_crouching and
			not Input.is_action_pressed("Shoot_Primary"))

func _on_direction_changed(facing_right: bool):
	# Handle character flipping
	_update_character_flip(facing_right)

func _update_character_flip(facing_right: bool):
	# Flip the character by rotating the rotation handle
	if facing_right:
		rotation_handle.rotation.y = 0
	else:
		rotation_handle.rotation.y = PI
