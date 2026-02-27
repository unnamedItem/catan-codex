class_name HexMath
extends RefCounted

static func add(a: Hex, b: Hex) -> Hex:
	return a.add(b)

static func subtract(a: Hex, b: Hex) -> Hex:
	return a.subtract(b)

static func neighbor(hex: Hex, direction: int) -> Hex:
	return add(hex, HexDirections.get_direction(direction))

static func neighbors(hex: Hex) -> Array[Hex]:
	var result: Array[Hex] = []
	for direction_index in range(6):
		result.append(neighbor(hex, direction_index))
	return result

static func length(hex: Hex) -> int:
	return int((abs(hex.q) + abs(hex.r) + abs(hex.s)) / 2)

static func distance(a: Hex, b: Hex) -> int:
	return length(subtract(a, b))

static func ring(center: Hex, radius: int) -> Array[Hex]:
	assert(radius >= 0, "Ring radius must be >= 0")
	if radius == 0:
		return [Hex.new(center.q, center.r, center.s)]

	var results: Array[Hex] = []
	var current := add(center, scale(HexDirections.get_direction(4), radius))
	for direction_index in range(6):
		for _step in range(radius):
			results.append(current)
			current = neighbor(current, direction_index)
	return results

static func spiral(center: Hex, radius: int) -> Array[Hex]:
	assert(radius >= 0, "Spiral radius must be >= 0")
	var results: Array[Hex] = [Hex.new(center.q, center.r, center.s)]
	for ring_radius in range(1, radius + 1):
		results.append_array(ring(center, ring_radius))
	return results

static func scale(hex: Hex, factor: int) -> Hex:
	return Hex.new(hex.q * factor, hex.r * factor, hex.s * factor)
