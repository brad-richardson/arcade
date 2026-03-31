extends Node2D
class_name FoodItem

enum FoodShape { RECTANGLE, PARALLELOGRAM, STAR_4, STAR_5, CROSS, STAR_6 }
enum FoodSize { SMALL, MEDIUM, LARGE }

const SIZE_RANGES: Dictionary = {
	FoodSize.SMALL: { "radius": 12.0, "worth": 1 },
	FoodSize.MEDIUM: { "radius": 25.0, "worth": 2 },
	FoodSize.LARGE: { "radius": 40.0, "worth": 3 },
}

const FOOD_COLORS: Array[Color] = [
	Color(1.0, 0.4, 0.6),
	Color(0.4, 1.0, 0.7),
	Color(1.0, 0.8, 0.3),
	Color(0.5, 0.7, 1.0),
	Color(1.0, 0.5, 0.2),
]

var food_size: FoodSize = FoodSize.SMALL
var food_shape: FoodShape = FoodShape.RECTANGLE
var radius: float = 12.0
var worth: int = 1
var color: Color = Color.WHITE
var locked: bool = false
var _rotation_speed: float = 0.0
var _points: PackedVector2Array = PackedVector2Array()


func setup(pos: Vector2, size: FoodSize, shape: FoodShape) -> void:
	position = pos
	food_size = size
	food_shape = shape
	var size_data: Dictionary = SIZE_RANGES[size]
	radius = size_data["radius"]
	worth = size_data["worth"]
	color = FOOD_COLORS[randi() % FOOD_COLORS.size()]
	_rotation_speed = randf_range(0.5, 1.5) * (1.0 if randf() > 0.5 else -1.0)
	_points = _generate_shape_points()


func _process(delta: float) -> void:
	rotation += _rotation_speed * delta
	queue_redraw()


func _draw() -> void:
	var draw_color: Color = color
	if locked:
		draw_color = Color(color, 0.25)
	draw_colored_polygon(_points, draw_color)
	var outline: Color = draw_color.lightened(0.3)
	for i: int in range(_points.size()):
		draw_line(_points[i], _points[(i + 1) % _points.size()], outline, 1.0, true)


func update_locked_state(max_eatable: float) -> void:
	locked = radius > max_eatable


func _generate_shape_points() -> PackedVector2Array:
	match food_shape:
		FoodShape.RECTANGLE:
			return _make_rectangle(radius * 1.2, radius * 0.6)
		FoodShape.PARALLELOGRAM:
			return _make_parallelogram(radius * 1.2, radius * 0.6, radius * 0.3)
		FoodShape.STAR_4:
			return _make_star(4, radius, radius * 0.4)
		FoodShape.STAR_5:
			return _make_star(5, radius, radius * 0.4)
		FoodShape.CROSS:
			return _make_cross(radius, radius * 0.35)
		FoodShape.STAR_6:
			return _make_star(6, radius, radius * 0.5)
	return PackedVector2Array()


func _make_rectangle(w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-w / 2, -h / 2), Vector2(w / 2, -h / 2),
		Vector2(w / 2, h / 2), Vector2(-w / 2, h / 2),
	])


func _make_parallelogram(w: float, h: float, slant: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-w / 2 + slant, -h / 2), Vector2(w / 2 + slant, -h / 2),
		Vector2(w / 2 - slant, h / 2), Vector2(-w / 2 - slant, h / 2),
	])


func _make_star(points_count: int, outer_r: float, inner_r: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(points_count * 2):
		var angle: float = TAU * i / (points_count * 2) - PI / 2.0
		var r: float = outer_r if i % 2 == 0 else inner_r
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	return pts


func _make_cross(size: float, thickness: float) -> PackedVector2Array:
	var s: float = size / 2.0
	var t: float = thickness / 2.0
	return PackedVector2Array([
		Vector2(-t, -s), Vector2(t, -s), Vector2(t, -t),
		Vector2(s, -t), Vector2(s, t), Vector2(t, t),
		Vector2(t, s), Vector2(-t, s), Vector2(-t, t),
		Vector2(-s, t), Vector2(-s, -t), Vector2(-t, -t),
	])
