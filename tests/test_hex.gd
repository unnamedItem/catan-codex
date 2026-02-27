extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_run()
	_finish()

func _run() -> void:
	var center := Hex.new(0, 0, 0)
	_assert(center.q + center.r + center.s == 0, "Hex invariant q+r+s==0 failed")

	var neighbors: Array[Hex] = HexMath.neighbors(center)
	_assert(neighbors.size() == 6, "neighbors() must return 6 hexes")

	_assert(HexMath.distance(center, center) == 0, "distance(center, center) must be 0")
	_assert(HexMath.distance(center, neighbors[0]) == 1, "distance(center, neighbor) must be 1")

	var ring_1: Array[Hex] = HexMath.ring(center, 1)
	_assert(ring_1.size() == 6, "ring(center,1) must return 6 hexes")

	var spiral_2: Array[Hex] = HexMath.spiral(center, 2)
	_assert(spiral_2.size() == 19, "spiral(center,2) must return 19 hexes")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("test_hex: PASS")
		quit(0)
		return

	printerr("test_hex: FAIL")
	for failure in _failures:
		printerr(" - ", failure)
	quit(1)
