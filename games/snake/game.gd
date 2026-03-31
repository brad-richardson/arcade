extends BaseGame


const MAP_SIZE: Vector2 = Vector2(3600, 6400)
const FOOD_COUNT: int = 120
const BORDER_COLOR: Color = Color(0.4, 0.4, 0.5)
const BORDER_WIDTH: float = 4.0
const BG_COLOR: Color = Color(0.08, 0.08, 0.12)
const GRID_COLOR: Color = Color(0.12, 0.12, 0.18)
const GRID_SPACING: float = 80.0

var game_over: bool = false
var segments_eaten: int = 0
var total_food: int = 0
var snake: Snake

@onready var camera: Camera2D = $Camera2D
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var score_label: Label = $UI/ScoreLabel


func _ready() -> void:
	super._ready()
	_spawn_snake()
	var joystick: FloatingJoystick = $UI/Joystick
	joystick.direction_changed.connect(_on_direction_changed)


func _process(delta: float) -> void:
	if game_over:
		return
	super._process(delta)

	camera.position = snake.position

	score_label.text = "Score: %d" % snake.segments_eaten

	if snake.check_self_collision():
		_end_game(false)
	elif snake.check_wall_collision(MAP_SIZE):
		_end_game(false)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), BG_COLOR)

	var x: float = GRID_SPACING
	while x < MAP_SIZE.x:
		var y: float = GRID_SPACING
		while y < MAP_SIZE.y:
			draw_circle(Vector2(x, y), 1.5, GRID_COLOR)
			y += GRID_SPACING
		x += GRID_SPACING

	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), BORDER_COLOR, false, BORDER_WIDTH)


func _spawn_snake() -> void:
	snake = Snake.new()
	snake.position = MAP_SIZE / 2.0
	add_child(snake)


func _end_game(cleared: bool) -> void:
	game_over = true
	var multiplier: int = 2 if cleared else 1
	var coins_earned: int = int(snake.segments_eaten * coin_rate * multiplier)
	if coins_earned > 0:
		CurrencyManager.add_coins(coins_earned)

	var end_text: String = "Map Cleared!" if cleared else "Game Over!"
	var vp: Vector2 = get_viewport_rect().size
	var label_size: Vector2 = Vector2(500, 200)
	var end_label: Label = Label.new()
	end_label.text = "%s\nScore: %d\nCoins: +%d" % [end_text, snake.segments_eaten, coins_earned]
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_label.add_theme_font_size_override("font_size", 48)
	end_label.size = label_size
	end_label.position = (vp - label_size) / 2.0
	$UI.add_child(end_label)

	await get_tree().create_timer(2.5).timeout
	SceneTransition.go_to_hub()


func _on_direction_changed(dir: Vector2) -> void:
	if not game_over and snake:
		snake.direction = dir


func _on_pause_pressed() -> void:
	pause_menu.show_pause()
