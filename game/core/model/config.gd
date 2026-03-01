class_name GameConfig
extends RefCounted

var _seed: int = 0
var map_rings: int = 2
var map_definition: Dictionary = {}
var player_count: int = 4
var starting_resources: Dictionary = {}
var enable_ports: bool = false
var enable_dev_cards: bool = false
var victory_points_to_win: int = 10
var sandbox_free_build: bool = true

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	_seed = int(data.get("seed", _seed))
	map_rings = int(data.get("map_rings", map_rings))
	map_definition = Dictionary(data.get("map_definition", {})).duplicate(true)
	player_count = int(data.get("player_count", player_count))
	starting_resources = Dictionary(data.get("starting_resources", {})).duplicate(true)
	enable_ports = bool(data.get("enable_ports", enable_ports))
	enable_dev_cards = bool(data.get("enable_dev_cards", enable_dev_cards))
	victory_points_to_win = int(data.get("victory_points_to_win", victory_points_to_win))
	sandbox_free_build = bool(data.get("sandbox_free_build", sandbox_free_build))

func to_dict() -> Dictionary:
	return {
		"seed": _seed,
		"map_rings": map_rings,
		"map_definition": map_definition.duplicate(true),
		"player_count": player_count,
		"starting_resources": starting_resources.duplicate(true),
		"enable_ports": enable_ports,
		"enable_dev_cards": enable_dev_cards,
		"victory_points_to_win": victory_points_to_win,
		"sandbox_free_build": sandbox_free_build,
	}

static func from_dict(data: Dictionary) -> GameConfig:
	return GameConfig.new(data)
