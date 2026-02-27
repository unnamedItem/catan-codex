class_name GamePhases
extends RefCounted

const SANDBOX: int = 0
const TURN_START: int = 1
const MAIN_ACTIONS: int = 2
const TURN_END: int = 3

static func all() -> Array[int]:
	return [SANDBOX, TURN_START, MAIN_ACTIONS, TURN_END]

static func to_name(phase: int) -> String:
	match phase:
		SANDBOX:
			return "SANDBOX"
		TURN_START:
			return "TURN_START"
		MAIN_ACTIONS:
			return "MAIN_ACTIONS"
		TURN_END:
			return "TURN_END"
		_:
			return "UNKNOWN"
