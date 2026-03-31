extends Node

signal item_unlocked(item_id: String)

## Maps item_id -> true for all unlocked items.
var _unlocked: Dictionary = {}


func _ready() -> void:
	var saved: Array = SaveManager.load_value("unlocks", "items", [])
	for item_id: String in saved:
		_unlocked[item_id] = true


func is_unlocked(item_id: String) -> bool:
	return _unlocked.has(item_id)


func unlock(item_id: String) -> bool:
	if is_unlocked(item_id):
		return true
	# TODO: Look up item cost from a catalog. For now, unlocks are free.
	_unlocked[item_id] = true
	_save_unlocks()
	item_unlocked.emit(item_id)
	return true


func get_unlocked_items() -> Array[String]:
	var items: Array[String] = []
	for key: String in _unlocked.keys():
		items.append(key)
	return items


func _save_unlocks() -> void:
	SaveManager.save_value("unlocks", "items", _unlocked.keys())
