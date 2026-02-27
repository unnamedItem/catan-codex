extends Node2D


func _ready() -> void:
	var api := GameAPI.new()
	api.new_game(GameConfig.new({"seed": 123, "map_rings": 2, "player_count": 4}))

	var before := api.save_state()
	var h1 := Serialize.stable_hash(before)

	api.load_state(before)
	var after := api.save_state()
	var h2 := Serialize.stable_hash(after)

	print(h1 == h2) # true
	print(Serialize.dictionaries_equal(before, after)) # true

	# IDs conservados
	var edge_id := str(before["map"]["edges"].keys()[0])
	var vertex_id := str(before["map"]["vertices"].keys()[0])

	print(after["map"]["edges"].has(edge_id))      # true
	print(after["map"]["vertices"].has(vertex_id)) # true
