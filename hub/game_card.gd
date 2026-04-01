extends PanelContainer


@onready var icon: TextureRect = %Icon
@onready var game_name: Label = %GameName
@onready var description: Label = %Description

var _game_data: Dictionary = {}

## Accent colors assigned per card index for visual variety.
const ACCENT_COLORS: Array[Color] = [
	Color(0.3, 0.55, 0.9, 1.0),   # blue
	Color(0.85, 0.35, 0.4, 1.0),  # red
	Color(0.3, 0.75, 0.5, 1.0),   # green
	Color(0.9, 0.6, 0.2, 1.0),    # orange
	Color(0.65, 0.4, 0.85, 1.0),  # purple
	Color(0.2, 0.7, 0.8, 1.0),    # teal
]

var _normal_style: StyleBoxFlat
var _accent_panel: PanelContainer


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_normal_style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	_accent_panel = $VBoxContainer/AccentBar


func setup(game_data: Dictionary, card_index: int = 0) -> void:
	_game_data = game_data

	if is_node_ready():
		_apply_data(card_index)
	else:
		ready.connect(_apply_data.bind(card_index))


func _apply_data(card_index: int = 0) -> void:
	game_name.text = _game_data.get("name", "Unknown")
	description.text = _game_data.get("description", "")

	var icon_path: String = _game_data.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)

	# Apply accent color based on card index
	var color: Color = ACCENT_COLORS[card_index % ACCENT_COLORS.size()]
	var accent_style: StyleBoxFlat = _accent_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	accent_style.bg_color = color
	_accent_panel.add_theme_stylebox_override("panel", accent_style)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_set_pressed_style()
			else:
				_set_normal_style()
				_launch_game()


func _set_pressed_style() -> void:
	var pressed: StyleBoxFlat = _normal_style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.22, 0.24, 0.3, 1.0)
	add_theme_stylebox_override("panel", pressed)


func _set_normal_style() -> void:
	add_theme_stylebox_override("panel", _normal_style)


func _launch_game() -> void:
	var game_id: String = _game_data.get("id", "")
	if game_id == "":
		return
	var scene_path: String = "res://games/%s/game.tscn" % game_id
	SceneTransition.change_scene(scene_path)
