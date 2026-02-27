extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_run()
	_finish()

func _run() -> void:
	var state := GameState.new()
	state.setup_new_game(GameConfig.new({"seed": 7, "map_rings": 1, "player_count": 2}))

	var edge_id: String = str(state.map.edges.keys()[0])
	var edge: EdgeState = state.map.get_edge(edge_id)
	edge.owner_player_id = 2
	var road_validation := BuildRules.can_build_road(state, 1, edge_id)
	_assert(not road_validation.ok and road_validation.code == "EDGE_OCCUPIED", "Road on occupied edge must be invalid")

	var vertex_id: String = str(state.map.vertices.keys()[0])
	var vertex: VertexState = state.map.get_vertex(vertex_id)
	vertex.owner_player_id = 2
	vertex.building = VertexState.BUILDING_SETTLEMENT
	var settlement_occupied := BuildRules.can_build_settlement(state, 1, vertex_id)
	_assert(not settlement_occupied.ok and settlement_occupied.code == "VERTEX_OCCUPIED", "Settlement on occupied vertex must be invalid")

	var distance_state := GameState.new()
	distance_state.setup_new_game(GameConfig.new({"seed": 9, "map_rings": 1, "player_count": 2}))
	var any_edge_id: String = str(distance_state.map.edges.keys()[0])
	var any_edge: EdgeState = distance_state.map.get_edge(any_edge_id)
	var a_id: String = any_edge.a
	var b_id: String = any_edge.b
	var a_vertex: VertexState = distance_state.map.get_vertex(a_id)
	a_vertex.owner_player_id = 2
	a_vertex.building = VertexState.BUILDING_SETTLEMENT
	var too_close := BuildRules.can_build_settlement(distance_state, 1, b_id)
	_assert(not too_close.ok and too_close.code == "VERTEX_TOO_CLOSE", "Adjacent settlement must fail distance rule")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("test_build_rules: PASS")
		quit(0)
		return

	printerr("test_build_rules: FAIL")
	for failure in _failures:
		printerr(" - ", failure)
	quit(1)
