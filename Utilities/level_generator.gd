extends Node3D
class_name LevelGenerator

signal generation_finished(spawn_xform: Transform3D)

# --- Designer inputs ---
@export var entrance_scene: PackedScene
@export var rooms_dir: String = "res://Rooms"
@export var target_room_count: int = 6

@onready var rooms_parent: Node3D = $"../Rooms"

# --- Node refs ---
var rng := RandomNumberGenerator.new()
var room_catalog: Array[PackedScene]

var _frontier: Array[Node3D] = []  # connectors we can still build from
var _placed_rooms: Array[Node3D] = []  # optional, handy for debugging

#debug vars:
var room_attempts: Dictionary = {}  # Key: room index, Value: {tries: 0, places: 0, rejects: 0}

func _ready():
	rng.randomize()
	room_catalog = _load_rooms_from_dir(rooms_dir)
	print("Loaded ", room_catalog.size(), " rooms! Here's the deets:")
	for i in range(room_catalog.size()):
		var temp_room = room_catalog[i].instantiate()
		var conns = _collect_connectors(temp_room)
		var conn_info = []
		for c in conns:
			conn_info.append({ "name": c.slot_name, "facing": c.facing, "size": c.size_cells })
		print("Room ", i, " (", temp_room.name, "): Connectors = ", conn_info)
		temp_room.queue_free()
	for i in range(room_catalog.size()):
		room_attempts[i] = { "tries": 0, "places": 0, "rejects": 0 }

func _load_rooms_from_dir(dir_path: String) -> Array[PackedScene]:
	var out: Array[PackedScene] = []
	var da := DirAccess.open(dir_path)
	if da == null: 
		push_warning("Rooms dir not found: %s" % dir_path)
		return out
	for f in da.get_files():
		if f.ends_with(".tscn"):
			var p := dir_path.path_join(f)
			var ps := ResourceLoader.load(p)
			if ps is PackedScene:
				var inst := (ps as PackedScene).instantiate()
				if inst.get_script() != null and inst.get_script().get_global_name() == "Room":
					out.append(ps)
					inst.queue_free()
	return out

func generate() -> void:
	# 1) Instance entrance and add to scene

	var root_room := _instance_room(entrance_scene, "Room_000_Entrance")
	rooms_parent.add_child(root_room)
	root_room.global_transform = Transform3D()  # place at origin
	
	_placed_rooms.clear()
	_frontier.clear()

	_placed_rooms.append(root_room)

	# seed frontier with all of entrance’s connectors
	for c in _collect_connectors(root_room):
		_frontier.append(c)

	# 3) Simple frontier growth: attach rooms until count reached or no openings
	var placed := [root_room]
	var fails := 0

	while placed.size() - 1 < target_room_count and _frontier.size() > 0 and fails < 100:  # Bump fails limit for now
		print("Frontier size=", _frontier.size(), " placed rooms=", placed.size())
		
		var rand_index = rng.randi_range(0, _frontier.size() - 1)
		var a_conn = _frontier[rand_index]
		print("Popped frontier connector: Name=", a_conn.slot_name, " Facing=", a_conn.facing, " Size=", a_conn.size_cells, " Pos=", a_conn.global_position)
		_frontier.remove_at(rand_index)  # Pull it out tentatively
		
		var found = false
		var shuffled_catalog = room_catalog.duplicate()  # Copy to shuffle without messing original
		shuffled_catalog.shuffle()  # Mix it up for variety!
		for candidate_scene in shuffled_catalog:
			var room_idx = shuffled_catalog.find(candidate_scene)  # Get index for tracking
			room_attempts[room_idx].tries += 1
			var b_room := _instance_room(candidate_scene)
			rooms_parent.add_child(b_room)
			
			var b_conn := _find_compatible_connector(b_room, a_conn)
			if b_conn != null:
				# Snap and finalize
				room_attempts[room_idx].places += 1
				_snap_room_b_to_a(b_room, b_conn, a_conn)
				placed.append(b_room)
				_placed_rooms.append(b_room)  # Fix: Add here if you want _placed_rooms updated
				
				var new_conns := _collect_connectors(b_room)
				new_conns = new_conns.filter(func(c): return c != b_conn)
				_frontier.append_array(new_conns)
				
				_frontier = _frontier.filter(func(c): return c != a_conn)
				found = true
				break
			else:
				room_attempts[room_idx].rejects += 1
				b_room.queue_free()
				fails += 1
			
		if not found:
			# Dead end? Add back randomly for another shot!
			var reinsert_index = rng.randi_range(0, _frontier.size())
			_frontier.insert(reinsert_index, a_conn)
			print("Shuffling back dead-end connector facing=", a_conn.facing, "—chaos mode engaged!")

	# 4) Find spawn marker in the entrance
	var spawn := _find_spawn_marker(root_room)
	var spawn_xform : Transform3D = spawn.global_transform

	print("Room Stats: Who got played?")
	for i in room_attempts:
		var stats = room_attempts[i]
		print("Room ", i, ": Tries=", stats.tries, " Places=", stats.places, " Rejects=", stats.rejects)

	# 5) Fire the signal so Level can move the player & hook camera
	emit_signal("generation_finished", spawn_xform)

# ------------- helpers -------------

func _find_spawn_marker(room: Node) -> Node3D:
	# Prefer group for flexibility
	for n in room.get_tree().get_nodes_in_group("player_spawn"):
		if room.is_ancestor_of(n) and n is Node3D:
			return n
	# Fallback: a well-known path/name
	var n2 := room.get_node_or_null("SpawnPoints/PlayerSpawn")
	if n2 is Node3D:
		return n2
	n2 = room.get_node_or_null("PlayerSpawn")
	return n2 if n2 is Node3D else null

func _instance_room(scene: PackedScene, name_hint: String = "") -> Node3D:
	var inst := scene.instantiate()
	if name_hint != "":
		inst.name = name_hint
	return inst

func _collect_connectors(room: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n in get_tree().get_nodes_in_group("Room_Connectors"):
		if room.is_ancestor_of(n):
			out.append(n)
	return out

func _pick_room_from_catalog() -> PackedScene:
	if room_catalog.is_empty():
		return null
	return room_catalog[rng.randi_range(0, room_catalog.size()-1)]

func _find_compatible_connector(b_room: Node, a_conn: Node) -> Node:
	var need_face = a_conn.get_script().call("opposite", a_conn.get("facing"))
	var need_size = a_conn.get("size_cells")
	var faces := []
	var sizes := []

	var facing_enum = a_conn.get("facing")
	var opposite    = a_conn.get_script().call("opposite", facing_enum)

	for n in _collect_connectors(b_room):
		faces.append(n.get("facing"))
		sizes.append(n.get("size_cells"))
		if n.get("facing") == opposite and n.get("size_cells") == need_size:
			return n
	print(b_room.name, " has faces=", faces, " sizes=", sizes, " need_face=", need_face, " need_size=", need_size)
	print("Rejected ", b_room.name, " for a_conn facing=", a_conn.facing, "—no match! Available faces=", faces, " sizes=", sizes, " needed opposite=", need_face, " size=", need_size)
	return null

func _snap_room_b_to_a(b_room: Node3D, b_conn: Node3D, a_conn: Node3D) -> void:
	# Align B so its connector sits on A's connector, facing inward
	var a := a_conn.global_transform
	var b := b_conn.global_transform

	var target_basis := Basis(a.basis.x, a.basis.y, a.basis.z)
	var target := Transform3D(target_basis, a.origin)

	var b_conn_to_room := b_room.global_transform.affine_inverse() * b
	b_room.global_transform = target * b_conn_to_room.affine_inverse()
