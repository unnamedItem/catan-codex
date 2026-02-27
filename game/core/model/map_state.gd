class_name MapState
extends RefCounted

var tiles: Dictionary = {}
var vertices: Dictionary = {}
var edges: Dictionary = {}
var ports: Dictionary = {}
var robber_hex: String = ""

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

func generate_rings(rings: int, seed: int = 0) -> void:
	assert(rings >= 0, "rings must be >= 0")
	clear()

	var center := Hex.new(0, 0, 0)
	var all_hexes: Array[Hex] = HexMath.spiral(center, rings)
	var rng := RNG.new(seed)

	for hex in all_hexes:
		var hex_key: String = hex.to_key()
		var terrain: int = _roll_terrain(rng)
		var token_number: int = _roll_token_number(terrain, rng)
		var tile := TileState.new(hex_key, terrain, token_number, false)
		tiles[hex_key] = tile

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

	if tiles.has(center.to_key()):
		robber_hex = center.to_key()
		var center_tile: TileState = tiles[robber_hex] as TileState
		center_tile.has_robber = true

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
