extends Node
class_name StateComponent

@export var initial_state: StringName

var state: EnemyState

func _ready() -> void:
    for child in get_children():
        if child is EnemyState:
            child.enemy = owner
            child.state_component = self
    if initial_state != StringName():
        state = get_node_or_null(initial_state) as EnemyState
        if state:
            state.enter()
        else:
            push_warning("Initial state '%s' not found" % initial_state)
    set_physics_process(true)

func transition_to(name: StringName) -> void:
    var new_state: EnemyState = get_node_or_null(name) as EnemyState
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
