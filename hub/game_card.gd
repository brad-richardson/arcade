extends PanelContainer


@onready var icon: TextureRect = %Icon
@onready var game_name: Label = %GameName
@onready var description: Label = %Description

var _game_data: Dictionary = {}


func setup(game_data: Dictionary) -> void:
	_game_data = game_data

	if is_node_ready():
		_apply_data()
	else:
		ready.connect(_apply_data)


func _apply_data() -> void:
	game_name.text = _game_data.get("name", "Unknown")
	description.text = _game_data.get("description", "")

	var icon_path: String = _game_data.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_launch_game()


func _launch_game() -> void:
	var game_id: String = _game_data.get("id", "")
	if game_id == "":
		return
	var scene_path: String = "res://games/%s/game.tscn" % game_id
	SceneTransition.change_scene(scene_path)
