extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_run()
	_finish()

func _run() -> void:
	var state := GameState.new()
	state.setup_new_game(GameConfig.new({"seed": 11, "map_rings": 1, "player_count": 2}))
	var before: Dictionary = state.to_dict()

	var wrong_player_id: int = state.current_player_id + 100
	var invalid_action := EndTurnAction.new(wrong_player_id)
	var invalid_result := ApplyAction.apply_action(state, invalid_action)

	_assert(not invalid_result.ok, "Invalid action must return ok=false")
	_assert(invalid_result.validation != null and invalid_result.validation.code == "NOT_YOUR_TURN", "Invalid action must return NOT_YOUR_TURN")
	_assert(invalid_result.events.size() == 1, "Invalid action must emit one event")
	if invalid_result.events.size() == 1:
		_assert(invalid_result.events[0].type == "INVALID_ACTION", "Invalid action event type must be INVALID_ACTION")

	var after: Dictionary = state.to_dict()
	_assert(Serialize.dictionaries_equal(before, after), "Invalid action must not mutate state")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("test_apply_action: PASS")
		quit(0)
		return

	printerr("test_apply_action: FAIL")
	for failure in _failures:
		printerr(" - ", failure)
	quit(1)
