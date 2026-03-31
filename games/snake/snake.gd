extends Node2D
class_name Snake


signal tier_changed(new_tier: int)

const SPEED: float = 200.0
const HEAD_SCALE: float = 1.2
const GRACE_FACTOR: float = 1.3
const PATH_RESOLUTION: float = 2.0
const SEGMENT_SPACING: float = 2.2

const TIERS: Array = [
	[0,  3, 15.0, Color(0.0, 1.0, 1.0)],
	[10, 4, 18.0, Color(0.2, 1.0, 0.3)],
	[20, 5, 21.0, Color(1.0, 1.0, 0.2)],
	[30, 6, 24.0, Color(1.0, 0.6, 0.1)],
	[40, 7, 27.0, Color(1.0, 0.2, 0.2)],
	[50, 8, 30.0, Color(0.7, 0.3, 1.0)],
]

var _direction: Vector2 = Vector2.UP
var direction: Vector2:
	get:
		return _direction
	set(value):
		if _direction.dot(value.normalized()) < -0.5:
			return
		_direction = value.normalized()
var segments_eaten: int = 0

var _segments: Array[Dictionary] = []
var _path: PackedVector2Array = PackedVector2Array()
var _polygon_cache: Dictionary = {}


func _ready() -> void:
	_segments.append(_make_segment_data())


func _process(delta: float) -> void:
	position += direction.normalized() * SPEED * delta

	if _path.is_empty() or position.distance_to(_path[_path.size() - 1]) >= PATH_RESOLUTION:
		_path.append(position)

	_trim_path()
	queue_redraw()


func _draw() -> void:
	var positions: Array[Vector2] = _get_segment_positions()
	for i: int in range(_segments.size() - 1, -1, -1):
		var seg: Dictionary = _segments[i]
		var pos: Vector2 = positions[i] if i < positions.size() else position
		var local_pos: Vector2 = pos - position
		var radius: float = seg["radius"]
		var color: Color = seg["color"]
		var sides: int = seg["sides"]
		if i == 0:
			radius *= HEAD_SCALE
		var points: PackedVector2Array = _get_polygon_points(sides, radius)
		var offset_points: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in points:
			offset_points.append(p + local_pos)
		draw_colored_polygon(offset_points, color)
		var outline_color: Color = Color(color, 0.8)
		outline_color = outline_color.lightened(0.3)
		for j: int in range(sides):
			draw_line(
				offset_points[j],
				offset_points[(j + 1) % sides],
				outline_color, 2.0, true
			)


func grow(count: int = 1) -> void:
	for i: int in range(count):
		segments_eaten += 1
		var old_tier: int = _get_tier_index(segments_eaten - 1)
		var new_tier: int = _get_tier_index(segments_eaten)
		_segments.append(_make_segment_data())
		if new_tier != old_tier:
			_segments[0] = _make_segment_data()
			tier_changed.emit(new_tier)


func get_head_radius() -> float:
	return _segments[0]["radius"] * HEAD_SCALE


func get_max_eatable_size() -> float:
	return _segments[0]["radius"] * GRACE_FACTOR


func get_current_tier() -> int:
	return _get_tier_index(segments_eaten)


func get_tier_color() -> Color:
	return TIERS[get_current_tier()][3]


func check_self_collision() -> bool:
	var positions: Array[Vector2] = _get_segment_positions()
	var head_r: float = get_head_radius()
	for i: int in range(4, positions.size()):
		var seg: Dictionary = _segments[i]
		var dist: float = position.distance_to(positions[i])
		if dist < head_r + seg["radius"] * 0.8:
			return true
	return false


func check_wall_collision(map_size: Vector2) -> bool:
	var r: float = get_head_radius()
	return position.x - r < 0.0 or position.x + r > map_size.x \
		or position.y - r < 0.0 or position.y + r > map_size.y


func get_segment_positions() -> Array[Vector2]:
	return _get_segment_positions()


func _get_segment_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	positions.append(position)

	if _path.size() < 2:
		return positions

	var accumulated_dist: float = 0.0

	for seg_i: int in range(1, _segments.size()):
		var spacing: float = _segments[seg_i - 1]["radius"] * SEGMENT_SPACING
		var target_dist: float = accumulated_dist + spacing

		var found: bool = false
		var total: float = 0.0
		var walk_idx: int = _path.size() - 1
		while walk_idx > 0:
			var d: float = _path[walk_idx].distance_to(_path[walk_idx - 1])
			if total + d >= target_dist:
				var t: float = (target_dist - total) / d
				positions.append(_path[walk_idx].lerp(_path[walk_idx - 1], t))
				found = true
				break
			total += d
			walk_idx -= 1

		if not found:
			positions.append(_path[0])

		accumulated_dist = target_dist

	return positions


func _make_segment_data() -> Dictionary:
	var tier_idx: int = _get_tier_index(segments_eaten)
	var tier: Array = TIERS[tier_idx]
	return {
		"tier": tier_idx,
		"sides": tier[1],
		"radius": tier[2],
		"color": tier[3],
	}


func _get_tier_index(eaten: int) -> int:
	var idx: int = 0
	for i: int in range(TIERS.size()):
		if eaten >= TIERS[i][0]:
			idx = i
	return idx


func _trim_path() -> void:
	if _segments.size() < 2 or _path.size() < 10:
		return
	var total_needed: float = 0.0
	for i: int in range(_segments.size()):
		total_needed += _segments[i]["radius"] * SEGMENT_SPACING
	total_needed *= 1.5

	var total: float = 0.0
	var keep_from: int = 0
	for i: int in range(_path.size() - 1, 0, -1):
		total += _path[i].distance_to(_path[i - 1])
		if total >= total_needed:
			keep_from = i - 1
			break

	if keep_from > 0:
		_path = _path.slice(keep_from)


func _get_polygon_points(sides: int, radius: float) -> PackedVector2Array:
	var key: int = sides * 1000 + int(radius)
	if _polygon_cache.has(key):
		return _polygon_cache[key]
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(sides):
		var angle: float = TAU * i / sides - PI / 2.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	_polygon_cache[key] = points
	return points
