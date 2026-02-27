class_name Hex
extends RefCounted

var q: int
var r: int
var s: int

func _init(p_q: int = 0, p_r: int = 0, p_s: int = 0) -> void:
	q = p_q
	r = p_r
	s = p_s
	assert(q + r + s == 0, "Hex invariant broken: q + r + s must equal 0")

func add(other: Hex) -> Hex:
	return Hex.new(q + other.q, r + other.r, s + other.s)

func subtract(other: Hex) -> Hex:
	return Hex.new(q - other.q, r - other.r, s - other.s)

func equals(other: Hex) -> bool:
	return q == other.q and r == other.r and s == other.s

func to_key() -> String:
	return "H:%d,%d,%d" % [q, r, s]

func to_dict() -> Dictionary:
	return {
		"q": q,
		"r": r,
		"s": s,
	}

static func from_dict(data: Dictionary) -> Hex:
	return Hex.new(
		int(data.get("q", 0)),
		int(data.get("r", 0)),
		int(data.get("s", 0))
	)

static func from_key(hex_key: String) -> Hex:
	var normalized := hex_key
	if normalized.begins_with("H:"):
		normalized = normalized.substr(2)
	var parts := normalized.split(",")
	assert(parts.size() == 3, "Invalid Hex key: expected three coordinates")
	return Hex.new(int(parts[0]), int(parts[1]), int(parts[2]))
