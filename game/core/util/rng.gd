class_name RNG
extends RefCounted

var seed_value: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(_seed: int = 0) -> void:
	reseed(_seed)

func reseed(_seed: int) -> void:
	seed_value = _seed
	_rng.seed = _seed

func randi_range(min_value: int, max_value: int) -> int:
	return _rng.randi_range(min_value, max_value)

func randf() -> float:
	return _rng.randf()

func to_dict() -> Dictionary:
	return {
		"seed": seed_value,
		"state": _rng.state,
	}

static func from_dict(data: Dictionary) -> RNG:
	var _seed: int = int(data.get("seed", 0))
	var instance := RNG.new(_seed)
	if data.has("state"):
		instance._rng.state = int(data.get("state", instance._rng.state))
	return instance
