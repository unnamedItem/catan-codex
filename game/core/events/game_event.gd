class_name GameEvent
extends RefCounted

var type: String = ""
var payload: Dictionary = {}
var turn_index: int = -1

func _init(p_type: String = "", p_payload: Dictionary = {}, p_turn_index: int = -1) -> void:
	type = p_type
	payload = p_payload.duplicate(true)
	turn_index = p_turn_index

func to_dict() -> Dictionary:
	return {
		"type": type,
		"payload": payload.duplicate(true),
		"turn_index": turn_index,
	}

static func from_dict(data: Dictionary) -> GameEvent:
	return GameEvent.new(
		String(data.get("type", "")),
		Dictionary(data.get("payload", {})),
		int(data.get("turn_index", -1))
	)
