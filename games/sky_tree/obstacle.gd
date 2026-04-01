extends Node2D
class_name TreeObstacles
## Manages obstacle spawning, storage, and rendering for the SkyTree game.
## Obstacle types: 0=none, 1=stone(lethal), 2=cloud(slow), 3=wind(push), 4=sunbeam(bonus)

const TYPE_STONE: int = 1
const TYPE_CLOUD: int = 2
const TYPE_WIND: int = 3
const TYPE_SUNBEAM: int = 4

const BASE_SPAWN_INTERVAL: float = 2.0
const MIN_SPAWN_INTERVAL: float = 0.6
const SPAWN_MARGIN: float = 60.0
const SUNBEAM_CHANCE: float = 0.12
const OBSTACLE_BUFFER: float = 40.0

const STONE_COLOR: Color = Color(0.45, 0.42, 0.4)
const STONE_OUTLINE: Color = Color(0.3, 0.28, 0.26)
const CLOUD_COLOR: Color = Color(0.15, 0.1, 0.2, 0.6)
const VINE_COLOR: Color = Color(0.5, 0.15, 0.1)
const WIND_COLOR: Color = Color(0.7, 0.85, 1.0, 0.3)
const SUNBEAM_COLOR: Color = Color(1.0, 0.9, 0.4, 0.12)

var obstacles: Array[Dictionary] = []
var _spawn_timer: float = 0.0
var _spawn_ahead_y: float = 0.0
var _camera_y: float = 0.0
var _viewport_height: float = 1280.0


func update_camera(cam_y: float, vp_height: float) -> void:
	_camera_y = cam_y
	_viewport_height = vp_height
	_spawn_ahead_y = cam_y - vp_height * 0.8


func spawn_tick(delta: float, height: float) -> void:
	var interval: float = maxf(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL - height / 5000.0)
	_spawn_timer += delta
	if _spawn_timer >= interval:
		_spawn_timer -= interval
		_spawn_obstacle(height)
		# Chance for sunbeam bonus zone.
		if randf() < SUNBEAM_CHANCE:
			_spawn_sunbeam()

	_cleanup()
	queue_redraw()


func get_active_obstacles() -> Array[Dictionary]:
	return obstacles


func _spawn_obstacle(height: float) -> void:
	var roll: float = randf()
	var obs_type: int
	var obs_size: Vector2

	if roll < 0.40:
		obs_type = TYPE_STONE
		obs_size = Vector2(randf_range(60.0, 120.0), randf_range(40.0, 70.0))
	elif roll < 0.60:
		obs_type = TYPE_CLOUD
		obs_size = Vector2(randf_range(100.0, 180.0), randf_range(80.0, 130.0))
	elif roll < 0.85:
		# Thorny vine — wide horizontal barrier, treated as stone (lethal).
		obs_type = TYPE_STONE
		obs_size = Vector2(randf_range(150.0, 300.0), 12.0)
	else:
		obs_type = TYPE_WIND
		obs_size = Vector2(120.0, 200.0)

	var y: float = _spawn_ahead_y
	var wind_dir: float = 0.0
	if obs_type == TYPE_WIND:
		wind_dir = -1.0 if randf() < 0.5 else 1.0

	# Try to find a non-overlapping position.
	var placed: bool = false
	for _attempt: int in range(10):
		var x: float = randf_range(-SkyTree.BOUNDS_X + SPAWN_MARGIN, SkyTree.BOUNDS_X - SPAWN_MARGIN)
		var candidate: Vector2 = Vector2(x, y)
		if _is_position_clear(candidate, obs_size):
			obstacles.append({
				"pos": candidate,
				"type": obs_type,
				"size": obs_size,
				"wind_dir": wind_dir,
			})
			placed = true
			break
	if not placed:
		# Skip this spawn rather than overlap.
		pass


func _spawn_sunbeam() -> void:
	var x: float = randf_range(-SkyTree.BOUNDS_X + 80.0, SkyTree.BOUNDS_X - 80.0)
	var y: float = _spawn_ahead_y
	obstacles.append({
		"pos": Vector2(x, y),
		"type": TYPE_SUNBEAM,
		"size": Vector2(120.0, 500.0),
		"wind_dir": 0.0,
	})


func _is_position_clear(pos: Vector2, sz: Vector2) -> bool:
	for obs: Dictionary in obstacles:
		# Only check against nearby obstacles (same vertical band).
		if absf(obs["pos"].y - pos.y) > 400.0:
			continue
		var min_dist_x: float = (sz.x + obs["size"].x) / 2.0 + OBSTACLE_BUFFER
		var min_dist_y: float = (sz.y + obs["size"].y) / 2.0 + OBSTACLE_BUFFER
		if absf(pos.x - obs["pos"].x) < min_dist_x and absf(pos.y - obs["pos"].y) < min_dist_y:
			return false
	return true


func _cleanup() -> void:
	var cutoff_y: float = _camera_y + _viewport_height
	var i: int = obstacles.size() - 1
	while i >= 0:
		if obstacles[i]["pos"].y > cutoff_y:
			obstacles.remove_at(i)
		i -= 1


func _draw() -> void:
	for obs: Dictionary in obstacles:
		var pos: Vector2 = obs["pos"] - position
		var sz: Vector2 = obs["size"]
		var half: Vector2 = sz / 2.0
		var obs_type: int = obs["type"]

		if obs_type == TYPE_STONE:
			if sz.y < 20.0:
				_draw_vine(pos, sz, half)
			else:
				_draw_stone(pos, sz, half)

		elif obs_type == TYPE_CLOUD:
			_draw_cloud(pos, sz)

		elif obs_type == TYPE_WIND:
			_draw_wind(pos, obs["wind_dir"])

		elif obs_type == TYPE_SUNBEAM:
			_draw_sunbeam(pos, sz, half)


func _draw_stone(pos: Vector2, sz: Vector2, half: Vector2) -> void:
	var rect: Rect2 = Rect2(pos - half, sz)
	# Layered stone with texture lines.
	draw_rect(rect, STONE_COLOR)
	# Cracks / texture lines.
	var crack_color: Color = Color(STONE_OUTLINE, 0.5)
	draw_line(pos + Vector2(-half.x * 0.6, -half.y * 0.3), pos + Vector2(half.x * 0.2, half.y * 0.1), crack_color, 1.0)
	draw_line(pos + Vector2(-half.x * 0.1, -half.y * 0.5), pos + Vector2(half.x * 0.4, half.y * 0.4), crack_color, 1.0)
	# Highlight on top edge.
	draw_line(Vector2(pos.x - half.x, pos.y - half.y), Vector2(pos.x + half.x, pos.y - half.y), Color(0.6, 0.55, 0.5), 2.0)
	# Shadow on bottom edge.
	draw_line(Vector2(pos.x - half.x, pos.y + half.y), Vector2(pos.x + half.x, pos.y + half.y), Color(0.2, 0.18, 0.16), 2.0)
	# Side edges.
	draw_rect(rect, STONE_OUTLINE, false, 2.0)


func _draw_vine(pos: Vector2, sz: Vector2, half: Vector2) -> void:
	# Main vine stem — curved look via multiple segments.
	var vine_dark: Color = Color(0.35, 0.1, 0.05)
	var thorn_color: Color = Color(0.7, 0.2, 0.15)
	var leaf_color: Color = Color(0.2, 0.45, 0.1, 0.7)
	# Thick main stem.
	draw_line(
		Vector2(pos.x - half.x, pos.y),
		Vector2(pos.x + half.x, pos.y),
		VINE_COLOR, 5.0, true
	)
	# Darker inner line.
	draw_line(
		Vector2(pos.x - half.x + 2.0, pos.y),
		Vector2(pos.x + half.x - 2.0, pos.y),
		vine_dark, 2.0, true
	)
	# Thorns — alternating up/down, varying size.
	var thorn_count: int = int(sz.x / 18.0)
	for t: int in range(thorn_count):
		var tx: float = pos.x - half.x + (t + 0.5) * (sz.x / float(thorn_count))
		var thorn_dir: float = -1.0 if t % 2 == 0 else 1.0
		var thorn_len: float = randf_range(8.0, 14.0) if t % 3 != 0 else 6.0
		# Thorn spike.
		draw_line(
			Vector2(tx, pos.y),
			Vector2(tx + 2.0, pos.y + thorn_dir * thorn_len),
			thorn_color, 2.0
		)
		# Small leaf on every 4th thorn.
		if t % 4 == 0:
			draw_circle(Vector2(tx, pos.y + thorn_dir * 4.0), 4.0, leaf_color)


func _draw_cloud(pos: Vector2, sz: Vector2) -> void:
	# Atmospheric fog/mist — soft, wide, very translucent.
	# Outer haze — barely visible, large.
	var haze: Color = Color(0.15, 0.12, 0.22, 0.08)
	draw_circle(pos, sz.x * 0.55, haze)
	draw_circle(pos + Vector2(-sz.x * 0.2, 0.0), sz.x * 0.45, haze)
	draw_circle(pos + Vector2(sz.x * 0.2, 0.0), sz.x * 0.4, haze)
	# Mid layer — slightly more visible.
	var mist: Color = Color(0.18, 0.14, 0.25, 0.15)
	draw_circle(pos, sz.x * 0.35, mist)
	draw_circle(pos + Vector2(-sz.x * 0.15, -sz.y * 0.05), sz.x * 0.28, mist)
	draw_circle(pos + Vector2(sz.x * 0.18, -sz.y * 0.03), sz.x * 0.25, mist)
	draw_circle(pos + Vector2(0.0, sz.y * 0.08), sz.x * 0.22, mist)
	# Dense core — still soft.
	var core: Color = Color(0.2, 0.16, 0.28, 0.22)
	draw_circle(pos + Vector2(-sz.x * 0.05, -sz.y * 0.02), sz.x * 0.2, core)
	draw_circle(pos + Vector2(sz.x * 0.08, 0.0), sz.x * 0.16, core)


func _draw_wind(pos: Vector2, dir: float) -> void:
	# Atmospheric wind — soft streaks that look like air currents, not arrows.
	# Soft haze in the gust area.
	var haze: Color = Color(0.7, 0.85, 1.0, 0.05)
	draw_circle(pos, 80.0, haze)
	draw_circle(pos + Vector2(dir * 20.0, 0.0), 60.0, haze)
	# Wispy streaks — thin, varying length, slightly curved.
	for row: int in range(7):
		var ry: float = pos.y - 80.0 + row * 25.0
		var wave: float = sin(float(row) * 1.8) * 12.0
		var line_len: float = 25.0 + float(row % 4) * 15.0
		var base_x: float = pos.x - dir * line_len * 0.5
		var tip_x: float = pos.x + dir * line_len * 0.5
		# Fade alpha — stronger in center, weaker at edges.
		var fade: float = 1.0 - absf(float(row) - 3.0) / 4.0
		var streak_c: Color = Color(0.75, 0.88, 1.0, 0.12 * fade)
		var thickness: float = 1.0 + fade * 1.5
		draw_line(Vector2(base_x, ry + wave), Vector2(tip_x, ry + wave), streak_c, thickness, true)


func _draw_sunbeam(pos: Vector2, sz: Vector2, half: Vector2) -> void:
	# Atmospheric light shaft — wide, soft, tapers from top.
	# Multiple soft overlapping layers for a volumetric feel.
	var beam_layers: int = 8
	for s: int in range(beam_layers):
		var t: float = float(s) / float(beam_layers)
		# Wider at top, narrower at bottom (light cone).
		var top_half_x: float = half.x * (1.0 - t * 0.5)
		var bot_half_x: float = half.x * (0.6 - t * 0.3)
		var alpha: float = 0.06 * (1.0 - t * 0.6)
		var warm: Color = Color(1.0, 0.92, 0.5, alpha)
		# Draw as a quad (trapezoid) via polygon.
		var top_y: float = pos.y - half.y
		var bot_y: float = pos.y + half.y
		var pts: PackedVector2Array = PackedVector2Array([
			Vector2(pos.x - top_half_x, top_y),
			Vector2(pos.x + top_half_x, top_y),
			Vector2(pos.x + bot_half_x, bot_y),
			Vector2(pos.x - bot_half_x, bot_y),
		])
		draw_colored_polygon(pts, warm)
	# Floating motes of light — scattered gently.
	for i: int in range(10):
		var mote_x: float = pos.x + sin(float(i) * 1.7 + 0.3) * half.x * 0.4
		var mote_y: float = pos.y - half.y + float(i) * sz.y / 10.0
		var mote_alpha: float = 0.15 + sin(float(i) * 3.1) * 0.08
		draw_circle(Vector2(mote_x, mote_y), 1.5 + sin(float(i)) * 0.5, Color(1.0, 1.0, 0.85, mote_alpha))
