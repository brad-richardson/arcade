extends Node2D
## Scripted demo of the dodge game for hub card preview.

const PREVIEW_SIZE: Vector2 = Vector2(320, 200)
const PLAYER_SIZE: Vector2 = Vector2(20, 20)
const BLOCK_SIZE: Vector2 = Vector2(20, 20)
const PLAYER_SPEED: float = 80.0
const FALL_SPEED: float = 120.0
const SPAWN_INTERVAL: float = 0.8

var _player_pos: Vector2
var _player_dir: float = 1.0
var _blocks: Array[Vector2] = []
var _spawn_timer: float = 0.0


func _ready() -> void:
	_player_pos = Vector2(PREVIEW_SIZE.x / 2.0, PREVIEW_SIZE.y - 30.0)


func _process(delta: float) -> void:
	_move_player(delta)
	_update_blocks(delta)
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_spawn_block()
	queue_redraw()


func _move_player(delta: float) -> void:
	for block_pos: Vector2 in _blocks:
		if block_pos.y > PREVIEW_SIZE.y - 60.0 and block_pos.y < PREVIEW_SIZE.y - 10.0:
			if absf(block_pos.x - _player_pos.x) < 25.0:
				_player_dir = signf(_player_pos.x - block_pos.x)
				if _player_dir == 0.0:
					_player_dir = 1.0
	if _player_pos.x < 20.0:
		_player_dir = 1.0
	elif _player_pos.x > PREVIEW_SIZE.x - 20.0:
		_player_dir = -1.0
	_player_pos.x += _player_dir * PLAYER_SPEED * delta


func _spawn_block() -> void:
	var x: float = randf_range(BLOCK_SIZE.x, PREVIEW_SIZE.x - BLOCK_SIZE.x)
	_blocks.append(Vector2(x, -BLOCK_SIZE.y))


func _update_blocks(delta: float) -> void:
	var i: int = _blocks.size() - 1
	while i >= 0:
		_blocks[i].y += FALL_SPEED * delta
		if _blocks[i].y > PREVIEW_SIZE.y + 20.0:
			_blocks.remove_at(i)
		i -= 1


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, PREVIEW_SIZE), Color(0.1, 0.1, 0.15))
	draw_rect(Rect2(_player_pos - PLAYER_SIZE / 2.0, PLAYER_SIZE), Color(0.2, 0.7, 1.0))
	for block_pos: Vector2 in _blocks:
		draw_rect(Rect2(block_pos - BLOCK_SIZE / 2.0, BLOCK_SIZE), Color(1.0, 0.3, 0.3))
