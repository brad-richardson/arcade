extends Node

const SAVE_PATH: String = "user://save_data.cfg"

var _config: ConfigFile = ConfigFile.new()
var _dirty: bool = false


func _ready() -> void:
	load_all()


func save_value(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)
	if not _dirty:
		_dirty = true
		_deferred_save.call_deferred()


func _deferred_save() -> void:
	if _dirty:
		_dirty = false
		save()


func load_value(section: String, key: String, default: Variant = null) -> Variant:
	return _config.get_value(section, key, default)


func save() -> void:
	var err: Error = _config.save(SAVE_PATH)
	if err != OK:
		push_error("SaveManager: Failed to save data, error code: %d" % err)


func load_all() -> void:
	var err: Error = _config.load(SAVE_PATH)
	if err == ERR_FILE_NOT_FOUND:
		pass # First launch, nothing to load.
	elif err != OK:
		push_error("SaveManager: Failed to load data, error code: %d" % err)
