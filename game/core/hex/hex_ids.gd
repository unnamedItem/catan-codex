class_name HexIds
extends RefCounted

static func vertex_id(hex: Hex, corner: int) -> String:
	assert(corner >= 0 and corner < 6, "Corner index must be in range [0..5]")
	var candidates: Array[Dictionary] = _equivalent_vertex_representations(hex, corner)
	assert(not candidates.is_empty(), "No canonical representation found for vertex")

	var best: Dictionary = candidates[0]
	var best_key: String = _representation_key(best)
	for candidate in candidates:
		var key: String = _representation_key(candidate)
		if key < best_key:
			best = candidate
			best_key = key

	return "V:%d,%d,%d:%d" % [
		int(best["q"]),
		int(best["r"]),
		int(best["s"]),
		int(best["corner"]),
	]

static func edge_id(vertex_a: String, vertex_b: String) -> String:
	assert(not vertex_a.is_empty(), "vertex_a must be non-empty")
	assert(not vertex_b.is_empty(), "vertex_b must be non-empty")
	assert(vertex_a != vertex_b, "An edge needs two different vertices")
	var ordered: Array[String] = [vertex_a, vertex_b]
	ordered.sort()
	return "E:%s|%s" % [ordered[0], ordered[1]]

static func edge_id_from_hex_side(hex: Hex, side: int) -> String:
	assert(side >= 0 and side < 6, "Side index must be in range [0..5]")
	var a: String = vertex_id(hex, side)
	var b: String = vertex_id(hex, (side + 1) % 6)
	return edge_id(a, b)

static func parse_vertex_id(id: String) -> Dictionary:
	assert(id.begins_with("V:"), "Invalid vertex id prefix")
	var content: String = id.substr(2)
	var split_corner: PackedStringArray = content.split(":")
	assert(split_corner.size() == 2, "Invalid vertex id format")
	var coords: PackedStringArray = split_corner[0].split(",")
	assert(coords.size() == 3, "Invalid vertex coordinates")

	return {
		"q": int(coords[0]),
		"r": int(coords[1]),
		"s": int(coords[2]),
		"corner": int(split_corner[1]),
	}

static func _equivalent_vertex_representations(hex: Hex, corner: int) -> Array[Dictionary]:
	var target_signature: String = _triplet_signature(_vertex_triplet(hex, corner))
	var representations: Array[Dictionary] = []

	for related_hex in _vertex_triplet(hex, corner):
		for related_corner in range(6):
			var signature: String = _triplet_signature(_vertex_triplet(related_hex, related_corner))
			if signature == target_signature:
				representations.append({
					"q": related_hex.q,
					"r": related_hex.r,
					"s": related_hex.s,
					"corner": related_corner,
				})
				break

	return representations

static func _vertex_triplet(hex: Hex, corner: int) -> Array[Hex]:
	assert(corner >= 0 and corner < 6, "Corner index must be in range [0..5]")
	var next_corner: int = (corner + 1) % 6
	return [
		hex,
		HexMath.neighbor(hex, corner),
		HexMath.neighbor(hex, next_corner),
	]

static func _triplet_signature(triplet: Array[Hex]) -> String:
	var keys: Array[String] = []
	for item in triplet:
		keys.append("%d,%d,%d" % [item.q, item.r, item.s])
	keys.sort()
	return "|".join(PackedStringArray(keys))

static func _representation_key(representation: Dictionary) -> String:
	return "%d,%d,%d:%d" % [
		int(representation["q"]),
		int(representation["r"]),
		int(representation["s"]),
		int(representation["corner"]),
	]
