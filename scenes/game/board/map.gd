@tool
extends Node2D

@export var map_data: JSON = null:
	set(value):
		map_data = value
		_refresh_preview()

@export var map_seed: int = 0:
	set(value):
		map_seed = value
		_refresh_preview()

@export var hex_radius: float = 54.0:
	set(value):
		hex_radius = max(value, 8.0)
		_refresh_preview()

var _preview_root: Node2D

func _ready() -> void:
	_refresh_preview()

func load_map(map_definition: Dictionary) -> void:
	var generated := MapState.new()
	var ok: bool = generated.generate_from_definition(map_definition, map_seed)
	if not ok:
		push_warning("Map generation failed: %s" % generated.last_generation_error)
		_clear_preview()
		return
	_render_map(generated)

func _refresh_preview() -> void:
	if not is_node_ready():
		return
	if map_data == null:
		_clear_preview()
		return
	if typeof(map_data.data) != TYPE_DICTIONARY:
		push_warning("map_data must contain a JSON dictionary.")
		_clear_preview()
		return
	load_map(Dictionary(map_data.data))

func _render_map(state: MapState) -> void:
	_ensure_preview_root()
	_clear_preview()

	var tile_keys: Array = state.tiles.keys()
	tile_keys.sort()
	for tile_key in tile_keys:
		var tile: TileState = state.tiles[tile_key] as TileState
		if tile == null:
			continue
		_preview_root.add_child(_build_tile_preview(tile))

func _build_tile_preview(tile: TileState) -> Node2D:
	var tile_node := Node2D.new()
	tile_node.name = _safe_node_name(tile.hex)

	var hex: Hex = Hex.from_key(tile.hex)
	tile_node.position = _hex_to_pixel(hex, hex_radius)

	var polygon := Polygon2D.new()
	polygon.polygon = _build_hex_points(hex_radius)
	polygon.color = _terrain_color(tile.terrain)
	tile_node.add_child(polygon)

	var label := Label.new()
	label.position = Vector2(-hex_radius * 0.6, -12)
	label.size = Vector2(hex_radius * 1.2, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = _tile_text(tile)
	tile_node.add_child(label)

	return tile_node

func _ensure_preview_root() -> void:
	if _preview_root != null and is_instance_valid(_preview_root):
		return
	_preview_root = get_node_or_null("Preview") as Node2D
	if _preview_root == null:
		_preview_root = Node2D.new()
		_preview_root.name = "Preview"
		add_child(_preview_root)
		if Engine.is_editor_hint():
			_preview_root.owner = get_tree().edited_scene_root

func _clear_preview() -> void:
	_ensure_preview_root()
	for child in _preview_root.get_children():
		child.queue_free()

func _hex_to_pixel(hex: Hex, radius: float) -> Vector2:
	var x: float = radius * sqrt(3.0) * (hex.q + (hex.r / 2.0))
	var y: float = radius * 1.5 * hex.r
	return Vector2(x, y)

func _build_hex_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for corner in range(6):
		var angle_deg: float = 60.0 * corner - 30.0
		var angle_rad: float = deg_to_rad(angle_deg)
		points.append(Vector2(radius * cos(angle_rad), radius * sin(angle_rad)))
	return points

func _terrain_color(terrain: int) -> Color:
	match terrain:
		TileState.TERRAIN_FOREST:
			return Color(0.25, 0.55, 0.28, 1.0)
		TileState.TERRAIN_HILLS:
			return Color(0.74, 0.42, 0.27, 1.0)
		TileState.TERRAIN_PASTURE:
			return Color(0.59, 0.76, 0.35, 1.0)
		TileState.TERRAIN_FIELDS:
			return Color(0.89, 0.79, 0.36, 1.0)
		TileState.TERRAIN_MOUNTAINS:
			return Color(0.52, 0.52, 0.58, 1.0)
		_:
			return Color(0.86, 0.80, 0.66, 1.0)

func _tile_text(tile: TileState) -> String:
	if tile.terrain == TileState.TERRAIN_DESERT:
		return "D"
	if tile.token_number > 0:
		return str(tile.token_number)
	return ""

func _safe_node_name(id: String) -> String:
	return id.replace(":", "_").replace(",", "_")
