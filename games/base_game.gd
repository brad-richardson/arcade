extends Node2D
class_name BaseGame
## Base class for all mini-games. Handles meta.json loading, time tracking,
## and coin awarding so individual games don't need to duplicate this logic.

var time_played: float = 0.0
var coin_rate: float = 1.0
var meta: Dictionary = {}


func _ready() -> void:
	_load_meta()


func _process(delta: float) -> void:
	time_played += delta


func _load_meta() -> void:
	var meta_path: String = get_scene_file_path().get_base_dir() + "/meta.json"
	var file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		meta = json.data
		coin_rate = meta.get("coin_rate", 1.0)


func award_coins() -> int:
	var coins_earned: int = int(time_played * coin_rate)
	if coins_earned > 0:
		CurrencyManager.add_coins(coins_earned)
	return coins_earned
