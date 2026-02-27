class_name ApplyAction
extends RefCounted

static func validate_action(state: GameState, action: Action) -> CoreErrors.ValidationResult:
	if state == null:
		return CoreErrors.fail("INVALID_STATE", "State cannot be null")
	if action == null:
		return CoreErrors.fail("INVALID_ACTION", "Action cannot be null")

	var turn_validation: CoreErrors.ValidationResult = _validate_turn(state, action)
	if not turn_validation.ok:
		return turn_validation
	if not GameFSM.is_action_allowed(state.phase, action.type):
		return CoreErrors.fail(
			"ACTION_NOT_ALLOWED_IN_PHASE",
			"Action is not allowed in current phase",
			{
				"phase": state.phase,
				"action_type": action.type,
			}
		)

	match action.type:
		ActionTypes.BUILD_ROAD:
			var edge_id: String = String(action.payload.get("edge_id", ""))
			if edge_id.is_empty():
				return CoreErrors.fail("MISSING_EDGE_ID", "BUILD_ROAD requires edge_id")
			return BuildRules.can_build_road(state, action.player_id, edge_id)
		ActionTypes.BUILD_SETTLEMENT:
			var vertex_id_settlement: String = String(action.payload.get("vertex_id", ""))
			if vertex_id_settlement.is_empty():
				return CoreErrors.fail("MISSING_VERTEX_ID", "BUILD_SETTLEMENT requires vertex_id")
			return BuildRules.can_build_settlement(state, action.player_id, vertex_id_settlement)
		ActionTypes.BUILD_CITY:
			var vertex_id_city: String = String(action.payload.get("vertex_id", ""))
			if vertex_id_city.is_empty():
				return CoreErrors.fail("MISSING_VERTEX_ID", "BUILD_CITY requires vertex_id")
			return BuildRules.can_build_city(state, action.player_id, vertex_id_city)
		ActionTypes.END_TURN:
			return CoreErrors.ok()
		ActionTypes.SET_PHASE:
			return CoreErrors.ok()
		_:
			return CoreErrors.fail("UNKNOWN_ACTION_TYPE", "Unsupported action type", {"type": action.type})

static func apply_action(
	state: GameState,
	action: Action,
	event_bus: EventBus = null
) -> CoreErrors.ApplyResult:
	var validation: CoreErrors.ValidationResult = validate_action(state, action)
	if not validation.ok:
		var invalid_event := GameEvent.new(
			"INVALID_ACTION",
			{
				"code": validation.code,
				"message": validation.message,
				"action_summary": action.summary() if action != null else {},
			},
			state.turn_index if state != null else -1
		)
		_push_events(event_bus, [invalid_event])
		return CoreErrors.ApplyResult.new(false, [invalid_event], validation)

	var events: Array[GameEvent] = []
	match action.type:
		ActionTypes.BUILD_ROAD:
			_apply_build_road(state, action, events)
		ActionTypes.BUILD_SETTLEMENT:
			_apply_build_settlement(state, action, events)
		ActionTypes.BUILD_CITY:
			_apply_build_city(state, action, events)
		ActionTypes.END_TURN:
			_apply_end_turn(state, action, events)
		ActionTypes.SET_PHASE:
			pass

	GameFSM.on_action_applied(state, action, events)
	_push_events(event_bus, events)
	return CoreErrors.ApplyResult.new(true, events, CoreErrors.ok())

static func _apply_build_road(state: GameState, action: Action, events: Array[GameEvent]) -> void:
	var edge_id: String = String(action.payload.get("edge_id", ""))
	var edge: EdgeState = state.map.get_edge(edge_id)
	edge.owner_player_id = action.player_id

	var player: PlayerState = state.get_player(action.player_id)
	if not player.roads.has(edge_id):
		player.roads.append(edge_id)

	events.append(GameEvent.new(
		"BUILD_PLACED",
		{
			"building_type": "ROAD",
			"owner_player_id": action.player_id,
			"id": edge_id,
		},
		state.turn_index
	))

static func _apply_build_settlement(state: GameState, action: Action, events: Array[GameEvent]) -> void:
	var vertex_id: String = String(action.payload.get("vertex_id", ""))
	var vertex: VertexState = state.map.get_vertex(vertex_id)
	vertex.owner_player_id = action.player_id
	vertex.building = VertexState.BUILDING_SETTLEMENT

	var player: PlayerState = state.get_player(action.player_id)
	if not player.settlements.has(vertex_id):
		player.settlements.append(vertex_id)

	events.append(GameEvent.new(
		"BUILD_PLACED",
		{
			"building_type": "SETTLEMENT",
			"owner_player_id": action.player_id,
			"id": vertex_id,
		},
		state.turn_index
	))

static func _apply_build_city(state: GameState, action: Action, events: Array[GameEvent]) -> void:
	var vertex_id: String = String(action.payload.get("vertex_id", ""))
	var vertex: VertexState = state.map.get_vertex(vertex_id)
	vertex.owner_player_id = action.player_id
	vertex.building = VertexState.BUILDING_CITY

	var player: PlayerState = state.get_player(action.player_id)
	if player.settlements.has(vertex_id):
		player.settlements.erase(vertex_id)
	if not player.cities.has(vertex_id):
		player.cities.append(vertex_id)

	events.append(GameEvent.new(
		"BUILD_PLACED",
		{
			"building_type": "CITY",
			"owner_player_id": action.player_id,
			"id": vertex_id,
		},
		state.turn_index
	))

static func _apply_end_turn(state: GameState, action: Action, events: Array[GameEvent]) -> void:
	var ended_player_id: int = state.current_player_id
	events.append(GameEvent.new(
		"TURN_ENDED",
		{"player_id": ended_player_id},
		state.turn_index
	))

	if state.turn_order.is_empty():
		state.current_player_id = -1
	else:
		var current_index: int = state.turn_order.find(ended_player_id)
		if current_index == -1:
			current_index = 0
		var next_index: int = (current_index + 1) % state.turn_order.size()
		state.current_player_id = state.turn_order[next_index]

	state.turn_index += 1
	events.append(GameEvent.new(
		"TURN_STARTED",
		{"player_id": state.current_player_id},
		state.turn_index
	))

static func _validate_turn(state: GameState, action: Action) -> CoreErrors.ValidationResult:
	if action.type == ActionTypes.SET_PHASE:
		return CoreErrors.ok()
	if state.current_player_id == -1:
		return CoreErrors.fail("NO_ACTIVE_PLAYER", "There is no active player")
	if action.player_id != state.current_player_id:
		return CoreErrors.fail(
			"NOT_YOUR_TURN",
			"Action player does not match current turn",
			{
				"current_player_id": state.current_player_id,
				"action_player_id": action.player_id,
			}
		)
	return CoreErrors.ok()

static func _push_events(event_bus: EventBus, events: Array[GameEvent]) -> void:
	if event_bus == null:
		return
	for event in events:
		event_bus.emit_event(event)
