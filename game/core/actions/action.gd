class_name Action
extends RefCounted

var type: String = ""
var player_id: int = -1
var payload: Dictionary = {}
var nonce: int = 0

func _init(
	p_type: String = "",
	p_player_id: int = -1,
	p_payload: Dictionary = {},
	p_nonce: int = 0
) -> void:
	type = p_type
	player_id = p_player_id
	payload = p_payload.duplicate(true)
	nonce = p_nonce

func to_dict() -> Dictionary:
	return {
		"type": type,
		"player_id": player_id,
		"payload": payload.duplicate(true),
		"nonce": nonce,
	}

static func from_dict(data: Dictionary) -> Action:
	return Action.new(
		String(data.get("type", "")),
		int(data.get("player_id", -1)),
		Dictionary(data.get("payload", {})),
		int(data.get("nonce", 0))
	)

func summary() -> Dictionary:
	return {
		"type": type,
		"player_id": player_id,
	}
