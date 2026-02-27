class_name BuildRules
extends RefCounted

const RESOURCE_WOOD: String = "WOOD"
const RESOURCE_BRICK: String = "BRICK"
const RESOURCE_SHEEP: String = "SHEEP"
const RESOURCE_WHEAT: String = "WHEAT"
const RESOURCE_ORE: String = "ORE"

static func can_build_road(state: GameState, player_id: int, edge_id: String) -> CoreErrors.ValidationResult:
	if state == null:
		return CoreErrors.fail("INVALID_STATE", "State cannot be null")
	if state.get_player(player_id) == null:
		return CoreErrors.fail("UNKNOWN_PLAYER", "Player does not exist", {"player_id": player_id})

	var edge: EdgeState = state.map.get_edge(edge_id)
	if edge == null:
		return CoreErrors.fail("EDGE_NOT_FOUND", "Edge does not exist", {"edge_id": edge_id})
	if edge.owner_player_id != -1:
		return CoreErrors.fail("EDGE_OCCUPIED", "Edge is already occupied", {"edge_id": edge_id})

	if _free_build_enabled(state):
		return CoreErrors.ok()
	if not road_would_connect_network(state, player_id, edge_id):
		return CoreErrors.fail("ROAD_NOT_CONNECTED", "Road must connect to your network", {"edge_id": edge_id})
	return CoreErrors.ok()

static func can_build_settlement(state: GameState, player_id: int, vertex_id: String) -> CoreErrors.ValidationResult:
	if state == null:
		return CoreErrors.fail("INVALID_STATE", "State cannot be null")
	if state.get_player(player_id) == null:
		return CoreErrors.fail("UNKNOWN_PLAYER", "Player does not exist", {"player_id": player_id})

	var vertex: VertexState = state.map.get_vertex(vertex_id)
	if vertex == null:
		return CoreErrors.fail("VERTEX_NOT_FOUND", "Vertex does not exist", {"vertex_id": vertex_id})
	if vertex.owner_player_id != -1 or vertex.building != VertexState.BUILDING_NONE:
		return CoreErrors.fail("VERTEX_OCCUPIED", "Vertex is already occupied", {"vertex_id": vertex_id})
	if not vertex_is_far_enough(state, vertex_id):
		return CoreErrors.fail("VERTEX_TOO_CLOSE", "Settlement must respect distance rule", {"vertex_id": vertex_id})

	if _free_build_enabled(state):
		return CoreErrors.ok()
	if not _vertex_connected_to_player_road(state, player_id, vertex_id):
		return CoreErrors.fail("SETTLEMENT_NOT_CONNECTED", "Settlement must connect to your road", {"vertex_id": vertex_id})
	return CoreErrors.ok()

static func can_build_city(state: GameState, player_id: int, vertex_id: String) -> CoreErrors.ValidationResult:
	if state == null:
		return CoreErrors.fail("INVALID_STATE", "State cannot be null")
	if state.get_player(player_id) == null:
		return CoreErrors.fail("UNKNOWN_PLAYER", "Player does not exist", {"player_id": player_id})

	var vertex: VertexState = state.map.get_vertex(vertex_id)
	if vertex == null:
		return CoreErrors.fail("VERTEX_NOT_FOUND", "Vertex does not exist", {"vertex_id": vertex_id})
	if vertex.owner_player_id != player_id:
		return CoreErrors.fail("NOT_VERTEX_OWNER", "City requires your settlement", {"vertex_id": vertex_id})
	if vertex.building != VertexState.BUILDING_SETTLEMENT:
		return CoreErrors.fail("NOT_SETTLEMENT", "City can only upgrade a settlement", {"vertex_id": vertex_id})
	return CoreErrors.ok()

static func road_would_connect_network(state: GameState, player_id: int, edge_id: String) -> bool:
	var edge: EdgeState = state.map.get_edge(edge_id)
	if edge == null:
		return false

	var player: PlayerState = state.get_player(player_id)
	if player == null:
		return false

	for road_id in player.roads:
		var owned_road: EdgeState = state.map.get_edge(road_id)
		if owned_road == null:
			continue
		if owned_road.a == edge.a or owned_road.a == edge.b or owned_road.b == edge.a or owned_road.b == edge.b:
			return true

	return _vertex_owned_by_player(state, player_id, edge.a) or _vertex_owned_by_player(state, player_id, edge.b)

static func vertex_is_far_enough(state: GameState, vertex_id: String) -> bool:
	for edge_key in state.map.edges.keys():
		var edge: EdgeState = state.map.edges[edge_key] as EdgeState
		if edge.a != vertex_id and edge.b != vertex_id:
			continue

		var neighbor_vertex_id: String = edge.b if edge.a == vertex_id else edge.a
		var neighbor: VertexState = state.map.get_vertex(neighbor_vertex_id)
		if neighbor == null:
			continue
		if neighbor.owner_player_id != -1 or neighbor.building != VertexState.BUILDING_NONE:
			return false
	return true

static func get_cost(building: int) -> Dictionary:
	match building:
		VertexState.BUILDING_SETTLEMENT:
			return {
				RESOURCE_WOOD: 1,
				RESOURCE_BRICK: 1,
				RESOURCE_SHEEP: 1,
				RESOURCE_WHEAT: 1,
			}
		VertexState.BUILDING_CITY:
			return {
				RESOURCE_WHEAT: 2,
				RESOURCE_ORE: 3,
			}
		_:
			# Roads are modeled through their own action and use building=-1 in this helper.
			return {
				RESOURCE_WOOD: 1,
				RESOURCE_BRICK: 1,
			}

static func _free_build_enabled(state: GameState) -> bool:
	if state.flags.has("sandbox_free_build"):
		return bool(state.flags.get("sandbox_free_build", true))
	return true

static func _vertex_connected_to_player_road(state: GameState, player_id: int, vertex_id: String) -> bool:
	for edge_key in state.map.edges.keys():
		var edge: EdgeState = state.map.edges[edge_key] as EdgeState
		if edge.owner_player_id != player_id:
			continue
		if edge.a == vertex_id or edge.b == vertex_id:
			return true
	return false

static func _vertex_owned_by_player(state: GameState, player_id: int, vertex_id: String) -> bool:
	var vertex: VertexState = state.map.get_vertex(vertex_id)
	if vertex == null:
		return false
	return vertex.owner_player_id == player_id and vertex.building != VertexState.BUILDING_NONE
