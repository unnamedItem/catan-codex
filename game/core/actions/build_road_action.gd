class_name BuildRoadAction
extends Action

var edge_id: String = ""

func _init(p_player_id: int = -1, p_edge_id: String = "", p_nonce: int = 0) -> void:
	edge_id = p_edge_id
	super(ActionTypes.BUILD_ROAD, p_player_id, {"edge_id": p_edge_id}, p_nonce)

func to_dict() -> Dictionary:
	payload["edge_id"] = edge_id
	return super.to_dict()

static func from_dict(data: Dictionary) -> BuildRoadAction:
	var payload_data: Dictionary = Dictionary(data.get("payload", {}))
	return BuildRoadAction.new(
		int(data.get("player_id", -1)),
		String(payload_data.get("edge_id", "")),
		int(data.get("nonce", 0))
	)
