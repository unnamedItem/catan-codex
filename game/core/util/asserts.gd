class_name CoreAsserts
extends RefCounted

static func require(condition: bool, message: String = "Assertion failed") -> void:
	assert(condition, message)

static func require_non_empty_string(value: String, message: String = "Expected non-empty string") -> void:
	assert(not value.is_empty(), message)
