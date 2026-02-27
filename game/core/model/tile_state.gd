class_name TileState
extends RefCounted

const TERRAIN_FOREST: int = 0
const TERRAIN_HILLS: int = 1
const TERRAIN_PASTURE: int = 2
const TERRAIN_FIELDS: int = 3
const TERRAIN_MOUNTAINS: int = 4
const TERRAIN_DESERT: int = 5

var hex: String = ""
var terrain: int = TERRAIN_DESERT
var token_number: int = 0
var has_robber: bool = false

func _init(
	p_hex: String = "",
	p_terrain: int = TERRAIN_DESERT,
	p_token_number: int = 0,
	p_has_robber: bool = false
) -> void:
	hex = p_hex
	terrain = p_terrain
	token_number = p_token_number
	has_robber = p_has_robber

func to_dict() -> Dictionary:
	return {
		"hex": hex,
		"terrain": terrain,
		"token_number": token_number,
		"has_robber": has_robber,
	}

static func from_dict(data: Dictionary) -> TileState:
	return TileState.new(
		String(data.get("hex", "")),
		int(data.get("terrain", TERRAIN_DESERT)),
		int(data.get("token_number", 0)),
		bool(data.get("has_robber", false))
	)
