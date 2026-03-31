extends Node2D
class_name SnakeEffects


var _particles: Array[Dictionary] = []
var _trail_particles: Array[Dictionary] = []

const TRAIL_EMIT_INTERVAL: float = 0.03
var _trail_timer: float = 0.0
var _trail_source: Node2D = null
var _trail_color: Color = Color.CYAN


func _process(delta: float) -> void:
	var i: int = _particles.size() - 1
	while i >= 0:
		var p: Dictionary = _particles[i]
		p["life"] -= delta
		if p["life"] <= 0.0:
			_particles.remove_at(i)
		else:
			p["pos"] += p["vel"] * delta
			p["vel"] *= 0.95
		i -= 1

	i = _trail_particles.size() - 1
	while i >= 0:
		var p: Dictionary = _trail_particles[i]
		p["life"] -= delta
		if p["life"] <= 0.0:
			_trail_particles.remove_at(i)
		else:
			p["pos"] += p["vel"] * delta
		i -= 1

	if _trail_source != null:
		_trail_timer -= delta
		if _trail_timer <= 0.0:
			_trail_timer = TRAIL_EMIT_INTERVAL
			_emit_trail_particle()

	if _particles.size() > 0 or _trail_particles.size() > 0:
		queue_redraw()


func _draw() -> void:
	for p: Dictionary in _trail_particles:
		var alpha: float = p["life"] / p["max_life"]
		var c: Color = Color(p["color"], alpha * 0.5)
		draw_circle(p["pos"], p["radius"] * alpha, c)

	for p: Dictionary in _particles:
		var alpha: float = p["life"] / p["max_life"]
		var c: Color = Color(p["color"], alpha)
		draw_circle(p["pos"], p["radius"] * alpha, c)


func set_trail_source(source: Node2D, color: Color) -> void:
	_trail_source = source
	_trail_color = color


func update_trail_color(color: Color) -> void:
	_trail_color = color


func emit_eat_burst(pos: Vector2, color: Color) -> void:
	for i: int in range(10):
		var angle: float = randf() * TAU
		var speed: float = randf_range(80.0, 200.0)
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": color,
			"radius": randf_range(3.0, 6.0),
			"life": randf_range(0.2, 0.5),
			"max_life": 0.5,
		})
	queue_redraw()


func emit_tier_burst(pos: Vector2, color: Color) -> void:
	for i: int in range(24):
		var angle: float = randf() * TAU
		var speed: float = randf_range(150.0, 350.0)
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": color,
			"radius": randf_range(4.0, 10.0),
			"life": randf_range(0.3, 0.7),
			"max_life": 0.7,
		})
	queue_redraw()


func emit_death_shatter(positions: Array[Vector2], segments: Array[Dictionary]) -> void:
	for i: int in range(positions.size()):
		var pos: Vector2 = positions[i]
		var color: Color = segments[i]["color"]
		for j: int in range(6):
			var angle: float = randf() * TAU
			var speed: float = randf_range(100.0, 300.0)
			_particles.append({
				"pos": pos,
				"vel": Vector2(cos(angle), sin(angle)) * speed,
				"color": color,
				"radius": randf_range(3.0, 8.0),
				"life": randf_range(0.4, 0.8),
				"max_life": 0.8,
			})
	queue_redraw()


func _emit_trail_particle() -> void:
	if _trail_source == null:
		return
	var pos: Vector2 = _trail_source.position
	var offset: Vector2 = Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	_trail_particles.append({
		"pos": pos + offset,
		"vel": Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)),
		"color": _trail_color,
		"radius": randf_range(2.0, 4.0),
		"life": 0.4,
		"max_life": 0.4,
	})
