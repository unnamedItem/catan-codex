class_name EdgeState
extends RefCounted

var a: String = ""
var b: String = ""
var owner_player_id: int = -1

func _init(p_a: String = "", p_b: String = "", p_owner_player_id: int = -1) -> void:
	if not p_a.is_empty() and not p_b.is_empty() and p_a > p_b:
		a = p_b
		b = p_a
	else:
		a = p_a
		b = p_b
	owner_player_id = p_owner_player_id

func to_dict() -> Dictionary:
	return {
		"a": a,
		"b": b,
		"owner_player_id": owner_player_id,
	}

static func from_dict(data: Dictionary) -> EdgeState:
	return EdgeState.new(
		String(data.get("a", "")),
		String(data.get("b", "")),
		int(data.get("owner_player_id", -1))
	)
