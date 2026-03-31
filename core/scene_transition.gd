extends Node

signal transition_started
signal transition_finished

const FADE_DURATION: float = 0.3
const HUB_SCENE: String = "res://hub/hub.tscn"

var _canvas_layer: CanvasLayer
var _color_rect: ColorRect
var _tween: Tween


func _ready() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	add_child(_canvas_layer)

	_color_rect = ColorRect.new()
	_color_rect.color = Color(0, 0, 0, 0)
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_color_rect)


func change_scene(path: String) -> void:
	if _tween and _tween.is_running():
		return

	transition_started.emit()
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# Fade to black.
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 1.0, FADE_DURATION)
	await _tween.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	# Fade from black.
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 0.0, FADE_DURATION)
	await _tween.finished

	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_finished.emit()


func go_to_hub() -> void:
	change_scene(HUB_SCENE)
