class_name EventBus
extends RefCounted

var _queue: Array[GameEvent] = []

func emit_event(event: GameEvent) -> void:
	_queue.append(event)

func emit_type(event_type: String, payload: Dictionary = {}, turn_index: int = -1) -> void:
	emit_event(GameEvent.new(event_type, payload, turn_index))

func poll_events() -> Array[GameEvent]:
	var out: Array[GameEvent] = _queue.duplicate()
	_queue.clear()
	return out

func clear() -> void:
	_queue.clear()

func size() -> int:
	return _queue.size()

func is_empty() -> bool:
	return _queue.is_empty()

func to_dict() -> Dictionary:
	var events_dict: Array[Dictionary] = []
	for event in _queue:
		events_dict.append(event.to_dict())
	return {
		"queue": events_dict,
	}

static func from_dict(data: Dictionary) -> EventBus:
	var bus := EventBus.new()
	var raw_queue: Array = Array(data.get("queue", []))
	for raw_event in raw_queue:
		if raw_event is Dictionary:
			bus.emit_event(GameEvent.from_dict(raw_event))
	return bus
