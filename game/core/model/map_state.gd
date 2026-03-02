class_name MapState
extends RefCounted

var tiles: Dictionary = {}
var vertices: Dictionary = {}
var edges: Dictionary = {}
var ports: Dictionary = {}
var robber_hex: String = ""
var last_generation_error: String = ""

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	var parsed: MapState = MapState.from_dict(data)
	tiles = parsed.tiles
	vertices = parsed.vertices
	edges = parsed.edges
	ports = parsed.ports
	robber_hex = parsed.robber_hex

func clear() -> void:
	tiles.clear()
	vertices.clear()
	edges.clear()
	ports.clear()
	robber_hex = ""
	last_generation_error = ""

func generate_rings(rings: int, _seed: int = 0) -> void:
	assert(rings >= 0, "rings must be >= 0")
	clear()

	var center := Hex.new(0, 0, 0)
	var all_hexes: Array[Hex] = HexMath.spiral(center, rings)
	var rng := RNG.new(_seed)

	for hex in all_hexes:
		var hex_key: String = hex.to_key()
		var terrain: int = _roll_terrain(rng)
		var token_number: int = _roll_token_number(terrain, rng)
		var tile := TileState.new(hex_key, terrain, token_number, false)
		tiles[hex_key] = tile
		_add_topology_for_hex(hex)

	if tiles.has(center.to_key()):
		robber_hex = center.to_key()
		var center_tile: TileState = tiles[robber_hex] as TileState
		center_tile.has_robber = true

func generate_from_definition(definition: Dictionary, _seed: int = 0) -> bool:
	clear()

	var explicit_layout: Array = Array(definition.get("tiles_layout", []))
	if not explicit_layout.is_empty():
		return _generate_from_explicit_layout(definition, explicit_layout, _seed)

	var raw_tiles: Array = Array(definition.get("tiles", []))
	if raw_tiles.is_empty():
		last_generation_error = "Map definition missing non-empty 'tiles' array."
		return false

	var terrains_pool: Array[int] = []
	for raw_entry in raw_tiles:
		var entry: Dictionary = Dictionary(raw_entry)
		var count: int = int(entry.get("count", 0))
		if count <= 0:
			continue

		var terrain: int = _terrain_from_definition_entry(entry)
		if terrain < TileState.TERRAIN_FOREST or terrain > TileState.TERRAIN_DESERT:
			last_generation_error = "Invalid terrain entry in map definition: %s" % [str(entry)]
			return false

		for _i in range(count):
			terrains_pool.append(terrain)

	if terrains_pool.is_empty():
		last_generation_error = "Map definition produced zero tiles."
		return false

	var all_hexes: Array[Hex] = _resolve_hexes_from_definition(definition, terrains_pool.size())
	if all_hexes.is_empty():
		return false
	if all_hexes.size() != terrains_pool.size():
		last_generation_error = "Hex count mismatch: expected %d, got %d." % [terrains_pool.size(), all_hexes.size()]
		return false

	var numbers_pool: Array = Array(definition.get("numbers", [])).duplicate()
	var expected_numbers: int = terrains_pool.size() - terrains_pool.count(TileState.TERRAIN_DESERT)
	if numbers_pool.size() != expected_numbers:
		last_generation_error = "Expected %d numbers for non-desert tiles, got %d." % [expected_numbers, numbers_pool.size()]
		return false

	var rng := RNG.new(_seed)
	_shuffle_array(terrains_pool, rng)

	var number_index: int = 0
	for i in range(all_hexes.size()):
		var hex: Hex = all_hexes[i]
		var terrain: int = terrains_pool[i]
		var token_number: int = 0
		if terrain != TileState.TERRAIN_DESERT:
			token_number = int(numbers_pool[number_index])
			number_index += 1

		var hex_key: String = hex.to_key()
		var tile := TileState.new(hex_key, terrain, token_number, false)
		tiles[hex_key] = tile
		_add_topology_for_hex(hex)

		if terrain == TileState.TERRAIN_DESERT and robber_hex.is_empty():
			robber_hex = hex_key
			tile.has_robber = true

	if robber_hex.is_empty():
		var center_key: String = Hex.new(0, 0, 0).to_key()
		if tiles.has(center_key):
			robber_hex = center_key
			var center_tile: TileState = tiles[robber_hex] as TileState
			center_tile.has_robber = true

	ports = _build_ports_from_definition(Array(definition.get("docks", [])), rng)
	return true

func _generate_from_explicit_layout(definition: Dictionary, layout: Array, _seed: int) -> bool:
	var used: Dictionary = {}
	var first_desert_key: String = ""

	for raw_tile in layout:
		var entry: Dictionary = Dictionary(raw_tile)
		var q: int = int(entry.get("q", 0))
		var r: int = int(entry.get("r", 0))
		var s: int = int(entry.get("s", 0))
		if q + r + s != 0:
			last_generation_error = "Invalid tile coordinate (q+r+s must be 0): %s" % [str(entry)]
			return false

		var hex := Hex.new(q, r, s)
		var hex_key: String = hex.to_key()
		if used.has(hex_key):
			last_generation_error = "Duplicated tile coordinate in tiles_layout: %s" % hex_key
			return false
		used[hex_key] = true

		var terrain: int = _terrain_from_definition_entry(entry)
		if terrain < TileState.TERRAIN_FOREST or terrain > TileState.TERRAIN_DESERT:
			last_generation_error = "Invalid terrain entry in tiles_layout: %s" % [str(entry)]
			return false

		var token_number: int = int(entry.get("number", entry.get("token_number", 0)))
		if terrain == TileState.TERRAIN_DESERT:
			token_number = 0
			if first_desert_key.is_empty():
				first_desert_key = hex_key

		var tile := TileState.new(hex_key, terrain, token_number, false)
		tiles[hex_key] = tile
		_add_topology_for_hex(hex)

		if bool(entry.get("has_robber", false)):
			robber_hex = hex_key
			tile.has_robber = true

	if tiles.is_empty():
		last_generation_error = "tiles_layout is empty after parsing."
		return false

	if robber_hex.is_empty():
		if not first_desert_key.is_empty() and tiles.has(first_desert_key):
			robber_hex = first_desert_key
			var desert_tile: TileState = tiles[robber_hex] as TileState
			desert_tile.has_robber = true
		else:
			var center_key: String = Hex.new(0, 0, 0).to_key()
			if tiles.has(center_key):
				robber_hex = center_key
				var center_tile: TileState = tiles[robber_hex] as TileState
				center_tile.has_robber = true

	var rng := RNG.new(_seed)
	ports = _build_ports_from_definition(Array(definition.get("docks", [])), rng)
	return true

func get_vertex(vertex_id: String) -> VertexState:
	if not vertices.has(vertex_id):
		return null
	return vertices[vertex_id] as VertexState

func get_edge(edge_id: String) -> EdgeState:
	if not edges.has(edge_id):
		return null
	return edges[edge_id] as EdgeState

func to_dict() -> Dictionary:
	var tiles_dict: Dictionary = {}
	for tile_key in tiles.keys():
		var tile: TileState = tiles[tile_key] as TileState
		tiles_dict[tile_key] = tile.to_dict()

	var vertices_dict: Dictionary = {}
	for vertex_key in vertices.keys():
		var vertex: VertexState = vertices[vertex_key] as VertexState
		vertices_dict[vertex_key] = vertex.to_dict()

	var edges_dict: Dictionary = {}
	for edge_key in edges.keys():
		var edge: EdgeState = edges[edge_key] as EdgeState
		edges_dict[edge_key] = edge.to_dict()

	return {
		"tiles": tiles_dict,
		"vertices": vertices_dict,
		"edges": edges_dict,
		"ports": ports.duplicate(true),
		"robber_hex": robber_hex,
	}

static func from_dict(data: Dictionary) -> MapState:
	var state := MapState.new()
	state.robber_hex = String(data.get("robber_hex", ""))
	state.ports = Dictionary(data.get("ports", {})).duplicate(true)

	var raw_tiles: Dictionary = Dictionary(data.get("tiles", {}))
	for tile_key in raw_tiles.keys():
		state.tiles[tile_key] = TileState.from_dict(Dictionary(raw_tiles[tile_key]))

	var raw_vertices: Dictionary = Dictionary(data.get("vertices", {}))
	for vertex_key in raw_vertices.keys():
		state.vertices[vertex_key] = VertexState.from_dict(Dictionary(raw_vertices[vertex_key]))

	var raw_edges: Dictionary = Dictionary(data.get("edges", {}))
	for edge_key in raw_edges.keys():
		state.edges[edge_key] = EdgeState.from_dict(Dictionary(raw_edges[edge_key]))

	return state

func _roll_terrain(rng: RNG) -> int:
	return rng.randi_range(TileState.TERRAIN_FOREST, TileState.TERRAIN_DESERT)

func _roll_token_number(terrain: int, rng: RNG) -> int:
	if terrain == TileState.TERRAIN_DESERT:
		return 0

	var candidate: int = rng.randi_range(2, 12)
	while candidate == 7:
		candidate = rng.randi_range(2, 12)
	return candidate

func _add_topology_for_hex(hex: Hex) -> void:
	for corner in range(6):
		var vertex_a: String = HexIds.vertex_id(hex, corner)
		var vertex_b: String = HexIds.vertex_id(hex, (corner + 1) % 6)

		if not vertices.has(vertex_a):
			vertices[vertex_a] = VertexState.new()
		if not vertices.has(vertex_b):
			vertices[vertex_b] = VertexState.new()

		var edge_key: String = HexIds.edge_id(vertex_a, vertex_b)
		if not edges.has(edge_key):
			edges[edge_key] = EdgeState.new(vertex_a, vertex_b, -1)

func _terrain_from_definition_entry(entry: Dictionary) -> int:
	if entry.has("terrain"):
		return int(entry.get("terrain", TileState.TERRAIN_DESERT))

	var terrain_id: String = String(entry.get("id", "")).to_upper()
	match terrain_id:
		"WOOD", "FOREST":
			return TileState.TERRAIN_FOREST
		"BRICK", "HILLS":
			return TileState.TERRAIN_HILLS
		"SHEEP", "PASTURE":
			return TileState.TERRAIN_PASTURE
		"WHEAT", "FIELDS":
			return TileState.TERRAIN_FIELDS
		"ORE", "MOUNTAINS":
			return TileState.TERRAIN_MOUNTAINS
		"DESERT":
			return TileState.TERRAIN_DESERT
		_:
			return -1

func _infer_rings_from_tile_count(tile_count: int) -> int:
	var rings: int = 0
	while true:
		var expected_count: int = 1 + (3 * rings * (rings + 1))
		if expected_count == tile_count:
			return rings
		if expected_count > tile_count:
			return -1
		rings += 1

	return -1

func _resolve_hexes_from_definition(definition: Dictionary, tile_count: int) -> Array[Hex]:
	var raw_coords: Array = Array(definition.get("cubic_coordinates", []))
	if not raw_coords.is_empty():
		var result: Array[Hex] = []
		var used: Dictionary = {}
		for raw_coord in raw_coords:
			var coord: Dictionary = Dictionary(raw_coord)
			var q: int = int(coord.get("q", 0))
			var r: int = int(coord.get("r", 0))
			var s: int = int(coord.get("s", 0))
			if q + r + s != 0:
				last_generation_error = "Invalid cubic coordinate (q+r+s must be 0): %s" % [str(coord)]
				return []

			var hex := Hex.new(q, r, s)
			var key: String = hex.to_key()
			if used.has(key):
				last_generation_error = "Duplicated cubic coordinate: %s" % key
				return []
			used[key] = true
			result.append(hex)

		if result.size() != tile_count:
			last_generation_error = "cubic_coordinates count (%d) must match tiles count (%d)." % [result.size(), tile_count]
			return []

		return result

	var rings: int = _infer_rings_from_tile_count(tile_count)
	if rings < 0:
		last_generation_error = "Tile count %d is not a full spiral. Provide 'cubic_coordinates' for this map mode (e.g. 30 tiles in 5-6 players)." % [tile_count]
		return []

	return HexMath.spiral(Hex.new(0, 0, 0), rings)

func _shuffle_array(items: Array, rng: RNG) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp

func _build_ports_from_definition(raw_docks: Array, rng: RNG) -> Dictionary:
	var result: Dictionary = {}
	var expanded: Array[String] = []

	for raw_dock in raw_docks:
		var dock: Dictionary = Dictionary(raw_dock)
		var count: int = int(dock.get("count", 0))
		if count <= 0:
			continue
		var port_id: String = String(dock.get("id", "")).to_upper()
		if port_id.is_empty():
			continue
		for _i in range(count):
			expanded.append(port_id)

	_shuffle_array(expanded, rng)

	for i in range(expanded.size()):
		result["P:%d" % i] = {
			"id": expanded[i],
		}

	return result
