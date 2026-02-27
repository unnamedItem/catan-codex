class_name HexDirections
extends RefCounted

const DIRECTION_COORDS: Array[Vector3i] = [
	Vector3i(1, 0, -1),
	Vector3i(1, -1, 0),
	Vector3i(0, -1, 1),
	Vector3i(-1, 0, 1),
	Vector3i(-1, 1, 0),
	Vector3i(0, 1, -1),
]

static func all() -> Array[Hex]:
	var result: Array[Hex] = []
	for coords in DIRECTION_COORDS:
		result.append(Hex.new(coords.x, coords.y, coords.z))
	return result

static func get_direction(index: int) -> Hex:
	assert(index >= 0 and index < DIRECTION_COORDS.size(), "Direction index must be in range [0..5]")
	var coords: Vector3i = DIRECTION_COORDS[index]
	return Hex.new(coords.x, coords.y, coords.z)
