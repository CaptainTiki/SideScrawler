# player.gd
extends CharacterBody3D
class_name Player

@export var speed: float = 6.5  # Adjusted for 3D scale (meters per second).
@export var jump_velocity: float = 6.5  # Adjusted for 3D.
@export var anim_tree: AnimationTree
@export var anim_player: AnimationPlayer
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Input state variables for animation logic.
var input_direction: Vector3 = Vector3.ZERO  # Now only X for side-scroller (positive X forward).
var is_pressing_up: bool = false  # "up" for aim up.
var is_pressing_down: bool = false  # "down" for crouch.

# Player state (as string matching animation node names).
var current_state: String = "Idle"

# Signal emitted when the state changes.
signal state_changed(new_state: String)

# Facing direction for model flip.
var facing_right: bool = true

@onready var playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")
@onready var land_detector: RayCast3D = $LandDetector

# Flags for landing logic.
var expecting_land: bool = false
var land_finished: bool = true

func _ready() -> void:
	anim_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "land":
		land_finished = true

func _physics_process(delta: float) -> void:
	# Update input states.
	# Calculate input direction only on X axis (side-scroller).
	var move_x: float = Input.get_action_strength("Move_Right") - Input.get_action_strength("Move_Left")
	input_direction = Vector3(move_x, 0, 0).normalized()
	
	is_pressing_up = Input.is_action_pressed("Move_Up")
	is_pressing_down = Input.is_action_pressed("Move_Down")
	
	# Determine new state based on inputs and physics.
	var new_state: String = current_state
	
	if is_on_floor():
		if abs(input_direction.x) > 0.0:  # Running left or right.
			new_state = "Run"
		else:
			if is_pressing_up:
				new_state = "AimUP"
			elif is_pressing_down:
				new_state = "Crouch"
			else:
				new_state = "Idle"
	else:
		# In air.
		if current_state in ["Idle", "Run", "AimUP", "Crouch"]:  # Just fell off without jumping.
			new_state = "Fall"
			expecting_land = true
	
	# Handle jump input (overrides to Jump_Start).
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_velocity
		new_state = "Jump_Start"
		expecting_land = true
	
	# Handle landing anticipation with raycast (while falling).
	if expecting_land and not is_on_floor() and velocity.y < 0 and land_detector.is_colliding() and current_state == "Fall":
		new_state = "Land"
		expecting_land = false
		land_finished = false
	
	# Prevent leaving Land state until animation finished.
	if current_state == "Land" and not land_finished:
		new_state = "Land"
	
	# Emit signal if state changed.
	if new_state != current_state:
		current_state = new_state
		state_changed.emit(current_state)
	
	# Sync logical state with animation tree in case of auto-transitions (e.g., Jump_Start to Fall).
	if playback.get_current_node() != current_state:
		current_state = playback.get_current_node()
	
	# Apply gravity (Y is up, so negative gravity on Y).
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Horizontal movement (X axis only, no Z).
	var horizontal_velocity: Vector3 = input_direction * speed
	velocity.x = horizontal_velocity.x
	velocity.z = 0.0  # Ensure no Z movement.
	
	move_and_slide()
	
	# Handle model flip based on movement direction.
	# Assuming rotating the entire CharacterBody3D is fine (if collision shape is symmetric).
	# If not, move this logic to rotate a child model node instead, e.g., $Model.rotation.y.
	if velocity.x > 0.01 and not facing_right:  # Small threshold to avoid jitter.
		facing_right = true
		rotation.y = 0  # Face positive X (forward).
	elif velocity.x < -0.01 and facing_right:
		facing_right = false
		rotation.y = PI  # Rotate 180 degrees to face negative X (left).
