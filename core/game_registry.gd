extends Node

signal games_loaded

var _games: Array[Dictionary] = []


func _ready() -> void:
	_scan_games()
	games_loaded.emit.call_deferred()


func get_games() -> Array[Dictionary]:
	return _games


func get_game(id: String) -> Dictionary:
	for game: Dictionary in _games:
		if game.get("id", "") == id:
			return game
	return {}


func _scan_games() -> void:
	var games_dir: String = "res://games/"
	var dir: DirAccess = DirAccess.open(games_dir)
	if dir == null:
		push_warning("GameRegistry: Could not open %s" % games_dir)
		return

	dir.list_dir_begin()
	var folder: String = dir.get_next()
	while folder != "":
		if dir.current_is_dir() and not folder.begins_with(".") and not folder.begins_with("_"):
			var meta_path: String = games_dir.path_join(folder).path_join("meta.json")
			if FileAccess.file_exists(meta_path):
				var entry: Dictionary = _parse_meta(meta_path, folder)
				if not entry.is_empty():
					_games.append(entry)
		folder = dir.get_next()
	dir.list_dir_end()


func _parse_meta(path: String, folder: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("GameRegistry: Could not open %s" % path)
		return {}

	var json: JSON = JSON.new()
	var err: Error = json.parse(file.get_as_text())
	if err != OK:
		push_warning("GameRegistry: Failed to parse %s — %s" % [path, json.get_error_message()])
		return {}

	var data: Dictionary = json.data
	# Ensure an id is present, falling back to the folder name.
	if not data.has("id"):
		data["id"] = folder
	return data
