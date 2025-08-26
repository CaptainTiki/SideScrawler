extends Camera3D
class_name SideScrollerCamera

var NodeToTrack: CharacterBody3D

func _init() -> void:
	set_process(false)

func set_node_to_track(tracked_node : CharacterBody3D) -> void:
	NodeToTrack = tracked_node
	set_process(true)

func _process(_delta: float) -> void:
	if NodeToTrack == null:
		return   # skip until hooked
	position.x = NodeToTrack.position.x
	position.y = NodeToTrack.position.y + 3
	pass
