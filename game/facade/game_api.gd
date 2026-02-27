class_name GameAPI
extends RefCounted

var _state: GameState = GameState.new()
var _event_bus: EventBus = EventBus.new()

func new_game(config: GameConfig) -> void:
	_state = GameState.new()
	_state.setup_new_game(config)
	_event_bus.clear()

func load_state(data: Dictionary) -> void:
	_state = GameState.from_dict(Serialize.deep_copy_dict(data))
	_event_bus.clear()

func save_state() -> Dictionary:
	return Serialize.deep_copy_dict(_state.to_dict())

func get_state() -> GameState:
	return _state

func get_snapshot() -> Dictionary:
	return save_state()

func list_legal_actions(player_id: int) -> Array[Action]:
	if _state == null:
		return []
	if _state.get_player(player_id) == null:
		return []

	var candidates: Array[Action] = []
	var allowed_types: Array[String] = GameFSM.get_allowed_action_types(_state.phase)

	if allowed_types.has(ActionTypes.BUILD_ROAD):
		for edge_id in _state.map.edges.keys():
			candidates.append(BuildRoadAction.new(player_id, String(edge_id)))
	if allowed_types.has(ActionTypes.BUILD_SETTLEMENT):
		for vertex_id in _state.map.vertices.keys():
			candidates.append(BuildSettlementAction.new(player_id, String(vertex_id)))
	if allowed_types.has(ActionTypes.BUILD_CITY):
		for vertex_id in _state.map.vertices.keys():
			candidates.append(BuildCityAction.new(player_id, String(vertex_id)))
	if allowed_types.has(ActionTypes.END_TURN):
		candidates.append(EndTurnAction.new(player_id))
	if allowed_types.has(ActionTypes.SET_PHASE):
		for phase_id in GamePhases.all():
			candidates.append(Action.new(ActionTypes.SET_PHASE, player_id, {"phase": phase_id}))

	var legal: Array[Action] = []
	for action in candidates:
		var validation: CoreErrors.ValidationResult = ApplyAction.validate_action(_state, action)
		if validation.ok:
			legal.append(action)
	return legal

func validate_action(action: Action) -> CoreErrors.ValidationResult:
	return ApplyAction.validate_action(_state, action)

func apply_action(action: Action) -> CoreErrors.ApplyResult:
	return ApplyAction.apply_action(_state, action, _event_bus)

func poll_events() -> Array[GameEvent]:
	return _event_bus.poll_events()

func peek_phase() -> int:
	if _state == null:
		return GamePhases.SANDBOX
	return _state.phase
