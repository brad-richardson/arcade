extends Node2D
class_name MagicalTree
## Handles tree growth, rendering, and collision detection.
## The tree is a series of connected points that grow upward.

signal tree_died

const SEGMENT_INTERVAL: float = 0.02
const MAX_STEER_SPEED: float = 280.0
const BOUNDS_X: float = 340.0
const BRANCH_INTERVAL: float = 80.0
const BRANCH_LENGTH_MIN: float = 20.0
const BRANCH_LENGTH_MAX: float = 45.0
const LEAF_RADIUS: float = 5.0

var growth_points: Array[Vector2] = []
var branches: Array[Dictionary] = []
var tip_position: Vector2 = Vector2.ZERO
var start_y: float = 0.0
var growth_speed: float = 120.0
var steer_direction: float = 0.0
var drift_strength: float = 1.0
var trunk_width: float = 12.0
var trunk_color: Color = Color(0.4, 0.26, 0.13)
var glow_color: Color = Color(0.2, 1.0, 0.3)
var alive: bool = true
var collision_forgiveness: float = 1.0
var can_burn: bool = false
var score_multiplier: float = 1.0
var slow_factor: float = 1.0

var _grow_timer: float = 0.0
var _time: float = 0.0
var _next_branch_height: float = BRANCH_INTERVAL
var _wind_push: float = 0.0


func setup(seed_config: Dictionary) -> void:
	growth_speed = seed_config.get("growth_speed", 120.0)
	drift_strength = seed_config.get("drift_strength", 1.0)
	trunk_width = seed_config.get("trunk_width", 12.0)
	trunk_color = seed_config.get("color", Color(0.4, 0.26, 0.13))
	glow_color = seed_config.get("glow_color", Color(0.2, 1.0, 0.3))
	collision_forgiveness = seed_config.get("collision_forgiveness", 1.0)
	can_burn = seed_config.get("can_burn", false)
	score_multiplier = seed_config.get("score_multiplier", 1.0)

	tip_position = position
	start_y = position.y
	growth_points.append(tip_position)


func grow(delta: float) -> void:
	if not alive:
		return

	_time += delta

	# Natural organic sway.
	var sway: float = sin(_time * 2.3) * drift_strength * 12.0
	sway += sin(_time * 5.7) * drift_strength * 4.0

	# Player steering + sway + wind.
	var steer_x: float = steer_direction * MAX_STEER_SPEED * drift_strength
	steer_x += sway + _wind_push

	# Decay wind push over time.
	_wind_push = move_toward(_wind_push, 0.0, 100.0 * delta)

	var effective_speed: float = growth_speed * slow_factor
	var direction: Vector2 = Vector2(steer_x, -effective_speed).normalized() * effective_speed
	tip_position += direction * delta

	# Add growth point at intervals for smooth rendering.
	_grow_timer += delta
	if _grow_timer >= SEGMENT_INTERVAL:
		_grow_timer -= SEGMENT_INTERVAL
		growth_points.append(tip_position)

		# Spawn decorative branches at height intervals.
		var height: float = get_height()
		if height >= _next_branch_height:
			_spawn_branch()
			_next_branch_height += BRANCH_INTERVAL + randf_range(-20.0, 20.0)

	queue_redraw()


func get_height() -> float:
	return start_y - tip_position.y


func check_bounds() -> bool:
	return absf(tip_position.x) > BOUNDS_X


func check_obstacle_collision(obstacles: Array) -> int:
	## Returns: 0 = no collision, 1 = lethal, 2 = cloud (slow), 3 = wind
	for obs: Dictionary in obstacles:
		var obs_pos: Vector2 = obs["pos"]
		var obs_type: int = obs["type"]
		var obs_size: Vector2 = obs["size"]

		var half: Vector2 = obs_size / 2.0
		var effective_half: Vector2 = half * collision_forgiveness

		# Simple AABB check against tree tip.
		if tip_position.x > obs_pos.x - effective_half.x \
				and tip_position.x < obs_pos.x + effective_half.x \
				and tip_position.y > obs_pos.y - effective_half.y \
				and tip_position.y < obs_pos.y + effective_half.y:
			return obs_type

	return 0


func apply_wind(strength: float) -> void:
	_wind_push += strength


func apply_slow(factor: float) -> void:
	slow_factor = factor


func clear_slow() -> void:
	slow_factor = 1.0


func die() -> void:
	alive = false
	tree_died.emit()


func _draw() -> void:
	if growth_points.size() < 2:
		return

	var total: int = growth_points.size()
	var visible_start: int = maxi(0, total - 800)

	# Draw trunk segments with tapering width and color gradient.
	for i: int in range(visible_start + 1, total):
		var from: Vector2 = growth_points[i - 1] - position
		var to: Vector2 = growth_points[i] - position

		var t: float = float(i) / float(total)
		var width: float = lerpf(trunk_width, trunk_width * 0.35, t)
		var color: Color = trunk_color.lerp(glow_color, t * 0.7)

		draw_line(from, to, color, width, true)

	# Draw glow at tip.
	if total > 0:
		var tip_local: Vector2 = tip_position - position
		var glow_alpha: float = 0.3 + sin(_time * 4.0) * 0.1
		draw_circle(tip_local, trunk_width * 0.8, Color(glow_color, glow_alpha))
		draw_circle(tip_local, trunk_width * 0.4, Color(glow_color, glow_alpha + 0.2))

	# Draw branches.
	for b: Dictionary in branches:
		var base: Vector2 = b["pos"] - position
		var end: Vector2 = base + b["dir"] * b["length"]
		var b_t: float = clampf((b["pos"].y - start_y) / (tip_position.y - start_y), 0.0, 1.0)
		var b_color: Color = trunk_color.lerp(glow_color, b_t * 0.5)
		var b_width: float = trunk_width * 0.3

		draw_line(base, end, b_color, b_width, true)

		# Leaf at branch tip.
		var leaf_color: Color = Color(glow_color, 0.7)
		draw_circle(end, LEAF_RADIUS, leaf_color)


func _spawn_branch() -> void:
	var side: float = -1.0 if randf() < 0.5 else 1.0
	var angle: float = randf_range(0.3, 0.8) * side
	var dir: Vector2 = Vector2(cos(angle), sin(angle) * 0.3 - 0.7).normalized()
	dir.x = absf(dir.x) * side

	branches.append({
		"pos": tip_position,
		"dir": dir,
		"length": randf_range(BRANCH_LENGTH_MIN, BRANCH_LENGTH_MAX),
	})
