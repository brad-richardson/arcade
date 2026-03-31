extends Node2D
class_name TreeObstacles
## Manages obstacle spawning, storage, and rendering for the magical tree game.
## Obstacle types: 0=none, 1=stone(lethal), 2=cloud(slow), 3=wind(push), 4=sunbeam(bonus)

const TYPE_STONE: int = 1
const TYPE_CLOUD: int = 2
const TYPE_WIND: int = 3
const TYPE_SUNBEAM: int = 4

const BASE_SPAWN_INTERVAL: float = 2.0
const MIN_SPAWN_INTERVAL: float = 0.6
const SPAWN_MARGIN: float = 60.0
const SUNBEAM_CHANCE: float = 0.12

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

	var x: float = randf_range(-BOUNDS_X + SPAWN_MARGIN, BOUNDS_X - SPAWN_MARGIN)
	var y: float = _spawn_ahead_y

	var wind_dir: float = 0.0
	if obs_type == TYPE_WIND:
		wind_dir = -1.0 if randf() < 0.5 else 1.0

	obstacles.append({
		"pos": Vector2(x, y),
		"type": obs_type,
		"size": obs_size,
		"wind_dir": wind_dir,
	})


const BOUNDS_X: float = 340.0


func _spawn_sunbeam() -> void:
	var x: float = randf_range(-BOUNDS_X + 80.0, BOUNDS_X - 80.0)
	var y: float = _spawn_ahead_y
	obstacles.append({
		"pos": Vector2(x, y),
		"type": TYPE_SUNBEAM,
		"size": Vector2(80.0, 300.0),
		"wind_dir": 0.0,
	})


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
				# Thorny vine — draw as line with thorns.
				draw_line(
					Vector2(pos.x - half.x, pos.y),
					Vector2(pos.x + half.x, pos.y),
					VINE_COLOR, 4.0, true
				)
				# Small thorns.
				var thorn_count: int = int(sz.x / 20.0)
				for t: int in range(thorn_count):
					var tx: float = pos.x - half.x + (t + 0.5) * (sz.x / float(thorn_count))
					var thorn_dir: float = -1.0 if t % 2 == 0 else 1.0
					draw_line(
						Vector2(tx, pos.y),
						Vector2(tx, pos.y + thorn_dir * 8.0),
						VINE_COLOR, 2.0
					)
			else:
				# Stone block.
				var rect: Rect2 = Rect2(pos - half, sz)
				draw_rect(rect, STONE_COLOR)
				draw_rect(rect, STONE_OUTLINE, false, 2.0)

		elif obs_type == TYPE_CLOUD:
			# Dark cloud — cluster of circles.
			var cloud_c: Color = CLOUD_COLOR
			draw_circle(pos, sz.x * 0.3, cloud_c)
			draw_circle(pos + Vector2(-sz.x * 0.2, -sz.y * 0.1), sz.x * 0.25, cloud_c)
			draw_circle(pos + Vector2(sz.x * 0.2, -sz.y * 0.05), sz.x * 0.22, cloud_c)
			draw_circle(pos + Vector2(0.0, sz.y * 0.15), sz.x * 0.2, cloud_c)

		elif obs_type == TYPE_WIND:
			# Wind gust — translucent arrows.
			var dir: float = obs["wind_dir"]
			var arrow_c: Color = WIND_COLOR
			for row: int in range(3):
				var ry: float = pos.y - 60.0 + row * 60.0
				var base_x: float = pos.x - dir * 30.0
				var tip_x: float = pos.x + dir * 30.0
				draw_line(Vector2(base_x, ry), Vector2(tip_x, ry), arrow_c, 3.0, true)
				# Arrowhead.
				draw_line(
					Vector2(tip_x, ry),
					Vector2(tip_x - dir * 10.0, ry - 8.0),
					arrow_c, 2.0, true
				)
				draw_line(
					Vector2(tip_x, ry),
					Vector2(tip_x - dir * 10.0, ry + 8.0),
					arrow_c, 2.0, true
				)

		elif obs_type == TYPE_SUNBEAM:
			# Golden vertical stripe.
			var rect: Rect2 = Rect2(pos - half, sz)
			draw_rect(rect, SUNBEAM_COLOR)
