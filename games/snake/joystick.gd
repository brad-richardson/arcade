extends Node2D
class_name FloatingJoystick

signal direction_changed(dir: Vector2)

const DEAD_ZONE: float = 15.0
const MAX_DISTANCE: float = 80.0
const RING_RADIUS: float = 60.0
const KNOB_RADIUS: float = 20.0
const RING_COLOR: Color = Color(1.0, 1.0, 1.0, 0.15)
const KNOB_COLOR: Color = Color(1.0, 1.0, 1.0, 0.4)

var _active: bool = false
var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
var _knob_pos: Vector2 = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed and not _active:
			_active = true
			_touch_index = touch.index
			_origin = touch.position
			_knob_pos = touch.position
			queue_redraw()
		elif not touch.pressed and touch.index == _touch_index:
			_active = false
			_touch_index = -1
			queue_redraw()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _touch_index:
			_knob_pos = drag.position
			var offset: Vector2 = _knob_pos - _origin
			if offset.length() > DEAD_ZONE:
				direction_changed.emit(offset.normalized())
			if offset.length() > MAX_DISTANCE:
				_knob_pos = _origin + offset.normalized() * MAX_DISTANCE
			queue_redraw()


func _process(_delta: float) -> void:
	var key_dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		key_dir.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		key_dir.x += 1.0
	if Input.is_action_pressed("ui_up"):
		key_dir.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		key_dir.y += 1.0
	if not _active and key_dir != Vector2.ZERO:
		direction_changed.emit(key_dir.normalized())


func _draw() -> void:
	if not _active:
		return
	draw_arc(_origin, RING_RADIUS, 0.0, TAU, 32, RING_COLOR, 2.0, true)
	draw_circle(_knob_pos, KNOB_RADIUS, KNOB_COLOR)


func is_active() -> bool:
	return _active
