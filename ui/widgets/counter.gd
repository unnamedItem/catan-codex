@tool
extends Control

@export var count: int = 0:
	set(value):
		count = value
		_refresh()

@export var icon: Texture2D:
	set(value):
		icon = value
		_refresh()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	if not is_node_ready():
		return

	var value_label := $PanelContainer/VBoxContainer/Value
	var icon_rect := $PanelContainer/VBoxContainer/Icon

	if value_label:
		value_label.text = str(count)
	if icon_rect:
		icon_rect.texture = icon
