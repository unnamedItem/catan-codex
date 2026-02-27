class_name GameState
extends RefCounted

var version: int = 1
var seed: int = 0
var turn_index: int = 0
var current_player_id: int = 0
var phase: int = GamePhases.MAIN_ACTIONS
var players: Dictionary = {}
var turn_order: Array[int] = []
var map: MapState = MapState.new()
var bank: BankState = BankState.new()
var flags: Dictionary = {}

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	var parsed: GameState = GameState.from_dict(data)
	version = parsed.version
	seed = parsed.seed
	turn_index = parsed.turn_index
	current_player_id = parsed.current_player_id
	phase = parsed.phase
	players = parsed.players
	turn_order = parsed.turn_order
	map = parsed.map
	bank = parsed.bank
	flags = parsed.flags

func setup_new_game(config: GameConfig) -> void:
	var config_data: Dictionary = config.to_dict()
	seed = int(config_data.get("seed", 0))
	turn_index = 0
	phase = GamePhases.MAIN_ACTIONS
	players.clear()
	turn_order.clear()
	flags.clear()
	bank = BankState.new()
	map = MapState.new()
	map.generate_rings(int(config_data.get("map_rings", 2)), seed)

	var starting_resources: Dictionary = Dictionary(config_data.get("starting_resources", {})).duplicate(true)
	var player_count: int = int(config_data.get("player_count", 4))
	for i in range(player_count):
		var player_id: int = i + 1
		var player := PlayerState.new({
			"id": player_id,
			"name": "Player %d" % player_id,
			"color_id": i,
			"resources": starting_resources,
		})
		players[player_id] = player
		turn_order.append(player_id)

	if turn_order.is_empty():
		current_player_id = -1
	else:
		current_player_id = turn_order[0]

func get_player(player_id: int) -> PlayerState:
	if not players.has(player_id):
		return null
	return players[player_id] as PlayerState

func player_add_resources(player_id: int, delta: Dictionary) -> bool:
	var player := get_player(player_id)
	if player == null:
		return false
	player.add_resources(delta)
	return true

func player_can_pay(player_id: int, cost: Dictionary) -> bool:
	var player := get_player(player_id)
	if player == null:
		return false
	return player.can_pay(cost)

func player_pay(player_id: int, cost: Dictionary) -> bool:
	var player := get_player(player_id)
	if player == null:
		return false
	return player.pay(cost)

func to_dict() -> Dictionary:
	var players_dict: Dictionary = {}
	for player_id in players.keys():
		var player: PlayerState = players[player_id] as PlayerState
		players_dict[str(player_id)] = player.to_dict()

	return {
		"version": version,
		"seed": seed,
		"turn_index": turn_index,
		"current_player_id": current_player_id,
		"phase": phase,
		"players": players_dict,
		"turn_order": turn_order.duplicate(),
		"map": map.to_dict(),
		"bank": bank.to_dict(),
		"flags": flags.duplicate(true),
	}

static func from_dict(data: Dictionary) -> GameState:
	var state := GameState.new()
	state.version = int(data.get("version", 1))
	state.seed = int(data.get("seed", 0))
	state.turn_index = int(data.get("turn_index", 0))
	state.current_player_id = int(data.get("current_player_id", 0))
	state.phase = int(data.get("phase", GamePhases.MAIN_ACTIONS))

	state.players.clear()
	var raw_players: Dictionary = Dictionary(data.get("players", {}))
	for player_key in raw_players.keys():
		state.players[int(player_key)] = PlayerState.from_dict(Dictionary(raw_players[player_key]))

	state.turn_order.clear()
	for raw_player_id in Array(data.get("turn_order", [])):
		state.turn_order.append(int(raw_player_id))

	state.map = MapState.from_dict(Dictionary(data.get("map", {})))
	state.bank = BankState.from_dict(Dictionary(data.get("bank", {})))
	state.flags = Dictionary(data.get("flags", {})).duplicate(true)
	return state
