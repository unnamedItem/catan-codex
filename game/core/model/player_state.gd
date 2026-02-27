class_name PlayerState
extends RefCounted

var id: int = -1
var name: String = ""
var color_id: int = 0
var resources: Dictionary = {}
var roads: Array[String] = []
var settlements: Array[String] = []
var cities: Array[String] = []
var victory_points: int = 0

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	var parsed: PlayerState = PlayerState.from_dict(data)
	id = parsed.id
	name = parsed.name
	color_id = parsed.color_id
	resources = parsed.resources
	roads = parsed.roads
	settlements = parsed.settlements
	cities = parsed.cities
	victory_points = parsed.victory_points

func add_resources(delta: Dictionary) -> void:
	for resource_key in delta.keys():
		var current: int = int(resources.get(resource_key, 0))
		resources[resource_key] = current + int(delta[resource_key])

func can_pay(cost: Dictionary) -> bool:
	for resource_key in cost.keys():
		if int(resources.get(resource_key, 0)) < int(cost[resource_key]):
			return false
	return true

func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	for resource_key in cost.keys():
		resources[resource_key] = int(resources.get(resource_key, 0)) - int(cost[resource_key])
	return true

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"color_id": color_id,
		"resources": resources.duplicate(true),
		"roads": roads.duplicate(),
		"settlements": settlements.duplicate(),
		"cities": cities.duplicate(),
		"victory_points": victory_points,
	}

static func from_dict(data: Dictionary) -> PlayerState:
	var state := PlayerState.new()
	state.id = int(data.get("id", -1))
	state.name = String(data.get("name", ""))
	state.color_id = int(data.get("color_id", 0))
	state.resources = Dictionary(data.get("resources", {})).duplicate(true)
	state.roads.clear()
	for edge_id in Array(data.get("roads", [])):
		state.roads.append(String(edge_id))
	state.settlements.clear()
	for vertex_id in Array(data.get("settlements", [])):
		state.settlements.append(String(vertex_id))
	state.cities.clear()
	for city_vertex_id in Array(data.get("cities", [])):
		state.cities.append(String(city_vertex_id))
	state.victory_points = int(data.get("victory_points", 0))
	return state
