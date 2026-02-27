class_name CoreErrors
extends RefCounted

class ValidationResult:
	extends RefCounted

	var ok: bool
	var code: String
	var message: String
	var details: Dictionary

	func _init(p_ok: bool = true, p_code: String = "OK", p_message: String = "", p_details: Dictionary = {}) -> void:
		ok = p_ok
		code = p_code
		message = p_message
		details = p_details.duplicate(true)

	func to_dict() -> Dictionary:
		return {
			"ok": ok,
			"code": code,
			"message": message,
			"details": details.duplicate(true),
		}

	static func from_dict(data: Dictionary) -> ValidationResult:
		return ValidationResult.new(
			bool(data.get("ok", false)),
			String(data.get("code", "UNKNOWN")),
			String(data.get("message", "")),
			Dictionary(data.get("details", {}))
		)

class ApplyResult:
	extends RefCounted

	var ok: bool
	var events: Array
	var validation: ValidationResult

	func _init(p_ok: bool = true, p_events: Array = [], p_validation: ValidationResult = null) -> void:
		ok = p_ok
		events = p_events.duplicate(true)
		validation = p_validation

	func to_dict() -> Dictionary:
		return {
			"ok": ok,
			"events": events.duplicate(true),
			"validation": validation.to_dict() if validation != null else {},
		}

	static func from_dict(data: Dictionary) -> ApplyResult:
		var validation_dict: Dictionary = Dictionary(data.get("validation", {}))
		var validation_obj: ValidationResult = null
		if not validation_dict.is_empty():
			validation_obj = ValidationResult.from_dict(validation_dict)
		return ApplyResult.new(
			bool(data.get("ok", false)),
			Array(data.get("events", [])),
			validation_obj
		)

static func ok() -> ValidationResult:
	return ValidationResult.new(true, "OK", "", {})

static func fail(code: String, message: String, details: Dictionary = {}) -> ValidationResult:
	return ValidationResult.new(false, code, message, details)
