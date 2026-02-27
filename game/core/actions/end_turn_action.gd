class_name EndTurnAction
extends Action

func _init(p_player_id: int = -1, p_nonce: int = 0) -> void:
	super(ActionTypes.END_TURN, p_player_id, {}, p_nonce)

static func from_dict(data: Dictionary) -> EndTurnAction:
	return EndTurnAction.new(
		int(data.get("player_id", -1)),
		int(data.get("nonce", 0))
	)
