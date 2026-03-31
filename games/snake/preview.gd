extends Node2D
## Scripted demo of the snake game for hub card preview.

const PREVIEW_MAP: Vector2 = Vector2(400, 400)
const DIRECTION_CHANGE_INTERVAL: float = 1.5

var _snake: Snake
var _timer: float = 0.0
var _food_timer: float = 0.0
var _directions: Array[Vector2] = [
	Vector2.RIGHT, Vector2(1, 1).normalized(), Vector2.DOWN,
	Vector2(-1, 1).normalized(), Vector2.LEFT, Vector2(-1, -1).normalized(),
	Vector2.UP, Vector2(1, -1).normalized(),
]
var _dir_index: int = 0


func _ready() -> void:
	_snake = Snake.new()
	_snake.position = PREVIEW_MAP / 2.0
	_snake.direction = _directions[0]
	add_child(_snake)
	_snake.grow(5)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= DIRECTION_CHANGE_INTERVAL:
		_timer = 0.0
		_dir_index = (_dir_index + 1) % _directions.size()
		_snake.direction = _directions[_dir_index]

	var margin: float = 30.0
	if _snake.position.x < margin:
		_snake.direction.x = absf(_snake.direction.x)
	elif _snake.position.x > PREVIEW_MAP.x - margin:
		_snake.direction.x = -absf(_snake.direction.x)
	if _snake.position.y < margin:
		_snake.direction.y = absf(_snake.direction.y)
	elif _snake.position.y > PREVIEW_MAP.y - margin:
		_snake.direction.y = -absf(_snake.direction.y)
	_snake.direction = _snake.direction.normalized()

	_food_timer += delta
	if _food_timer >= 2.0 and _snake.segments_eaten < 30:
		_food_timer = 0.0
		_snake.grow(1)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, PREVIEW_MAP), Color(0.08, 0.08, 0.12))
	draw_rect(Rect2(Vector2.ZERO, PREVIEW_MAP), Color(0.3, 0.3, 0.4), false, 2.0)
