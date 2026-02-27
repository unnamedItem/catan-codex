class_name GameFSM
extends RefCounted

static func get_allowed_action_types(phase: int) -> Array[String]:
	match phase:
		GamePhases.SANDBOX:
			return [
				ActionTypes.BUILD_ROAD,
				ActionTypes.BUILD_SETTLEMENT,
				ActionTypes.BUILD_CITY,
				ActionTypes.END_TURN,
				ActionTypes.SET_PHASE,
			]
		GamePhases.MAIN_ACTIONS:
			return [
				ActionTypes.BUILD_ROAD,
				ActionTypes.BUILD_SETTLEMENT,
				ActionTypes.BUILD_CITY,
				ActionTypes.END_TURN,
				ActionTypes.SET_PHASE,
			]
		GamePhases.TURN_START:
			return [ActionTypes.SET_PHASE]
		GamePhases.TURN_END:
			return [ActionTypes.SET_PHASE]
		_:
			return []

static func is_action_allowed(phase: int, action_type: String) -> bool:
	return get_allowed_action_types(phase).has(action_type)

static func on_action_applied(state: GameState, action: Action, events: Array[GameEvent]) -> void:
	if state == null or action == null:
		return

	if action.type == ActionTypes.SET_PHASE:
		var target_phase: int = int(action.payload.get("phase", state.phase))
		if target_phase != state.phase:
			_transition_phase(state, target_phase, events)
		return

	if action.type == ActionTypes.END_TURN:
		_transition_phase(state, GamePhases.TURN_END, events)
		_transition_phase(state, GamePhases.TURN_START, events)
		_transition_phase(state, GamePhases.MAIN_ACTIONS, events)

static func _transition_phase(state: GameState, to_phase: int, events: Array[GameEvent]) -> void:
	var from_phase: int = state.phase
	if from_phase == to_phase:
		return
	state.phase = to_phase
	events.append(GameEvent.new(
		"PHASE_CHANGED",
		{
			"from": from_phase,
			"to": to_phase,
		},
		state.turn_index
	))
