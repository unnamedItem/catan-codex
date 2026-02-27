class_name VertexState
extends RefCounted

const BUILDING_NONE: int = 0
const BUILDING_SETTLEMENT: int = 1
const BUILDING_CITY: int = 2

var owner_player_id: int = -1
var building: int = BUILDING_NONE

func _init(p_owner_player_id: int = -1, p_building: int = BUILDING_NONE) -> void:
	owner_player_id = p_owner_player_id
	building = p_building

func to_dict() -> Dictionary:
	return {
		"owner_player_id": owner_player_id,
		"building": building,
	}

static func from_dict(data: Dictionary) -> VertexState:
	return VertexState.new(
		int(data.get("owner_player_id", -1)),
		int(data.get("building", BUILDING_NONE))
	)
