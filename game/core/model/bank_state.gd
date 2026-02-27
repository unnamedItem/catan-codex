class_name BankState
extends RefCounted

const DEFAULT_STOCK: Dictionary = {
	"WOOD": 19,
	"BRICK": 19,
	"SHEEP": 19,
	"WHEAT": 19,
	"ORE": 19,
}

var stock: Dictionary = DEFAULT_STOCK.duplicate(true)
var unlimited: bool = true

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	var parsed: BankState = BankState.from_dict(data)
	stock = parsed.stock
	unlimited = parsed.unlimited

func can_remove(resources: Dictionary) -> bool:
	if unlimited:
		return true
	for resource_key in resources.keys():
		if int(stock.get(resource_key, 0)) < int(resources[resource_key]):
			return false
	return true

func remove(resources: Dictionary) -> bool:
	if not can_remove(resources):
		return false
	if unlimited:
		return true
	for resource_key in resources.keys():
		stock[resource_key] = int(stock.get(resource_key, 0)) - int(resources[resource_key])
	return true

func add(resources: Dictionary) -> void:
	if unlimited:
		return
	for resource_key in resources.keys():
		stock[resource_key] = int(stock.get(resource_key, 0)) + int(resources[resource_key])

func to_dict() -> Dictionary:
	return {
		"stock": stock.duplicate(true),
		"unlimited": unlimited,
	}

static func from_dict(data: Dictionary) -> BankState:
	var state := BankState.new()
	state.stock = Dictionary(data.get("stock", DEFAULT_STOCK)).duplicate(true)
	state.unlimited = bool(data.get("unlimited", true))
	return state
