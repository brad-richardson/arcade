extends Node2D
class_name TreeEffects
## Particle effects for the magical tree game: growth sparkles, leaves, death burst.

var _particles: Array[Dictionary] = []

const TRAIL_EMIT_INTERVAL: float = 0.04
var _trail_timer: float = 0.0
var _trail_source: MagicalTree = null
var _trail_color: Color = Color.GREEN


func _process(delta: float) -> void:
	var i: int = _particles.size() - 1
	while i >= 0:
		var p: Dictionary = _particles[i]
		p["life"] -= delta
		if p["life"] <= 0.0:
			_particles.remove_at(i)
		else:
			p["pos"] += p["vel"] * delta
			p["vel"] *= 0.97
		i -= 1

	# Emit growth trail from tree tip.
	if _trail_source != null and _trail_source.alive:
		_trail_timer -= delta
		if _trail_timer <= 0.0:
			_trail_timer = TRAIL_EMIT_INTERVAL
			_emit_growth_sparkle()

	if _particles.size() > 0:
		queue_redraw()


func _draw() -> void:
	for p: Dictionary in _particles:
		var alpha: float = p["life"] / p["max_life"]
		var c: Color = Color(p["color"], alpha)
		var r: float = p["radius"] * alpha
		draw_circle(p["pos"], r, c)


func set_trail_source(source: MagicalTree) -> void:
	_trail_source = source
	_trail_color = source.glow_color


func emit_death_burst(pos: Vector2, color: Color) -> void:
	for i: int in range(30):
		var angle: float = randf() * TAU
		var speed: float = randf_range(60.0, 250.0)
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": color.lerp(Color.WHITE, randf() * 0.3),
			"radius": randf_range(3.0, 8.0),
			"life": randf_range(0.5, 1.2),
			"max_life": 1.2,
		})
	queue_redraw()


func emit_milestone_burst(pos: Vector2, color: Color) -> void:
	for i: int in range(16):
		var angle: float = randf() * TAU
		var speed: float = randf_range(100.0, 280.0)
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": Color(color, 0.9),
			"radius": randf_range(4.0, 9.0),
			"life": randf_range(0.3, 0.7),
			"max_life": 0.7,
		})
	queue_redraw()


func _emit_growth_sparkle() -> void:
	if _trail_source == null:
		return
	var pos: Vector2 = _trail_source.tip_position
	var offset: Vector2 = Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
	_particles.append({
		"pos": pos + offset,
		"vel": Vector2(randf_range(-15.0, 15.0), randf_range(-30.0, 5.0)),
		"color": _trail_color.lerp(Color.WHITE, randf() * 0.5),
		"radius": randf_range(1.5, 3.5),
		"life": randf_range(0.3, 0.6),
		"max_life": 0.6,
	})
