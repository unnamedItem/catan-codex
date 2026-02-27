class_name ActionTypes
extends RefCounted

const BUILD_ROAD: String = "BUILD_ROAD"
const BUILD_SETTLEMENT: String = "BUILD_SETTLEMENT"
const BUILD_CITY: String = "BUILD_CITY"
const END_TURN: String = "END_TURN"
const SET_PHASE: String = "SET_PHASE"

static func all() -> Array[String]:
	return [
		BUILD_ROAD,
		BUILD_SETTLEMENT,
		BUILD_CITY,
		END_TURN,
		SET_PHASE,
	]
