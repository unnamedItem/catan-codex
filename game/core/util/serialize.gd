class_name Serialize
extends RefCounted

static func deep_copy_dict(data: Dictionary) -> Dictionary:
	return data.duplicate(true)

static func deep_copy_array(data: Array) -> Array:
	return data.duplicate(true)

static func clone_variant(value: Variant) -> Variant:
	if value is Dictionary:
		return Dictionary(value).duplicate(true)
	if value is Array:
		return Array(value).duplicate(true)
	return value

static func stable_sorted_keys(data: Dictionary) -> Array:
	var keys: Array = data.keys()
	keys.sort()
	return keys

static func canonicalize(value: Variant) -> Variant:
	if value is Dictionary:
		var source: Dictionary = value
		var sorted: Dictionary = {}
		var keys: Array = stable_sorted_keys(source)
		for key in keys:
			sorted[key] = canonicalize(source[key])
		return sorted

	if value is Array:
		var source_array: Array = value
		var out: Array = []
		for item in source_array:
			out.append(canonicalize(item))
		return out

	return value

static func stable_json_string(value: Variant) -> String:
	return JSON.stringify(canonicalize(value))

static func stable_hash(value: Variant) -> int:
	return hash(stable_json_string(value))

static func dictionaries_equal(a: Dictionary, b: Dictionary) -> bool:
	return stable_json_string(a) == stable_json_string(b)
