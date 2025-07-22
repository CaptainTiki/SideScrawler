extends CharacterBody3D
class_name Player

# Movement settings
@export var speed: float = 5.0
@export var jump_velocity: float = 14.0
@export var gravity: float = 35.0

# State variables
var is_grounded: bool = true
var is_moving: bool = false
var is_aim_up: bool = false
var is_crouching: bool = false
var facing_right: bool = true
var is_idle: bool = true

# Signals for animation system
signal grounded_changed(grounded: bool)
signal movement_changed(moving: bool)
signal direction_changed(facing_right: bool)
signal aim_up_changed(aiming_up: bool)
signal crouch_changed(crouching: bool)
signal idle_activated()

func _ready():
	# Initialize grounded state
	_update_grounded_state()

func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_apply_gravity(delta)
	_apply_movement()
	_update_states()
	
	move_and_slide()

func _handle_input(delta: float):
	# Handle jump
	if Input.is_action_just_pressed("Jump") and is_grounded:
		velocity.y = jump_velocity
	
	# Handle horizontal movement
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("Move_Left"):
		input_dir.x -= 1
	if Input.is_action_pressed("Move_Right"):
		input_dir.x += 1
	
	# Handle vertical inputs (aim up/crouch)
	var new_aim_up = Input.is_action_pressed("Move_Up")
	var new_crouch = Input.is_action_pressed("Move_Down")
	
	# Update aim up state
	if new_aim_up != is_aim_up:
		is_aim_up = new_aim_up
		aim_up_changed.emit(is_aim_up)
	
	# Update crouch state
	if new_crouch != is_crouching:
		is_crouching = new_crouch
		crouch_changed.emit(is_crouching)
	
	# Update movement state
	var new_moving = input_dir.length() > 0
	if new_moving != is_moving:
		is_moving = new_moving
		movement_changed.emit(is_moving)
	
	# Update facing direction
	if input_dir.x != 0:
		var new_facing_right = input_dir.x > 0
		if new_facing_right != facing_right:
			facing_right = new_facing_right
			direction_changed.emit(facing_right)
	
	# Apply horizontal movement
	if is_moving:
		velocity.x = input_dir.x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 2 * delta)
		
	if not is_moving and not is_aim_up and not is_crouching and is_grounded:
		idle_activated.emit()

func _apply_gravity(delta):
	if not is_grounded:
		velocity.y -= gravity * delta

func _apply_movement():
	# Any additional movement logic can go here
	pass

func _update_states():
	_update_grounded_state()

func _update_grounded_state():
	var new_grounded = is_on_floor()
	if new_grounded != is_grounded:
		is_grounded = new_grounded
		grounded_changed.emit(is_grounded)
