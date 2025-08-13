extends Node
class_name StateComponent

@export var initial_state: EnemyState

var state: EnemyState

func _ready() -> void:
	for child in get_children():
		if child is EnemyState:
			child.enemy = owner
			child.state_component = self
	set_physics_process(true)
	transition_to(initial_state)

func transition_to(state_name: EnemyState) -> void:
	var new_state: EnemyState = state_name
	if new_state:
		if state:
			state.exit()
		state = new_state
		state.enter()
	else:
		push_warning("State '%s' not found" % name)

func _physics_process(delta: float) -> void:
	if state:
		state.physics_update(delta)
