# RoomConnector.gd

extends Node3D
class_name RoomConnector

enum Facing { NORTH, EAST, SOUTH, WEST, UP, DOWN }

@export var slot_name: String = ""
@export var facing: Facing = Facing.NORTH
@export var size_cells: Vector2i = Vector2i(1, 1)

static func opposite(dir: int) -> int:
	match dir:
		Facing.NORTH: return Facing.SOUTH
		Facing.SOUTH: return Facing.NORTH
		Facing.EAST:  return Facing.WEST
		Facing.WEST:  return Facing.EAST
		Facing.UP:    return Facing.DOWN
		Facing.DOWN:  return Facing.UP
		_:            return dir
