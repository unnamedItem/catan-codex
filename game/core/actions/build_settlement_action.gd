class_name BuildSettlementAction
extends Action

var vertex_id: String = ""

func _init(p_player_id: int = -1, p_vertex_id: String = "", p_nonce: int = 0) -> void:
	vertex_id = p_vertex_id
	super(ActionTypes.BUILD_SETTLEMENT, p_player_id, {"vertex_id": p_vertex_id}, p_nonce)

func to_dict() -> Dictionary:
	payload["vertex_id"] = vertex_id
	return super.to_dict()

static func from_dict(data: Dictionary) -> BuildSettlementAction:
	var payload_data: Dictionary = Dictionary(data.get("payload", {}))
	return BuildSettlementAction.new(
		int(data.get("player_id", -1)),
		String(payload_data.get("vertex_id", "")),
		int(data.get("nonce", 0))
	)
