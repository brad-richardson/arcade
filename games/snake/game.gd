extends BaseGame


const MAP_SIZE: Vector2 = Vector2(3600, 6400)
const FOOD_COUNT: int = 120
const FOOD_MARGIN: float = 100.0
const FOOD_BUFFER: float = 8.0
const MAX_PLACEMENT_ATTEMPTS: int = 20
const SPAWN_SAFE_RADIUS: float = 300.0
const BORDER_COLOR: Color = Color(0.4, 0.4, 0.5)
const BORDER_WIDTH: float = 4.0
const BG_COLOR: Color = Color(0.08, 0.08, 0.12)
const GRID_COLOR: Color = Color(0.2, 0.2, 0.28)
const GRID_SPACING: float = 80.0

var game_over: bool = false
var total_food: int = 0
var snake: Snake
var _food_container: Node2D
var _effects: SnakeEffects

@onready var camera: Camera2D = $Camera2D
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var score_label: Label = $UI/ScoreLabel


func _ready() -> void:
	super._ready()
	_food_container = Node2D.new()
	add_child(_food_container)
	_spawn_food()
	_spawn_snake()
	_effects = SnakeEffects.new()
	add_child(_effects)
	_effects.set_trail_source(snake, snake.get_tier_color())
	snake.tier_changed.connect(_on_tier_changed)
	var joystick: FloatingJoystick = $UI/Joystick
	joystick.direction_changed.connect(_on_direction_changed)


func _process(delta: float) -> void:
	if game_over:
		return
	super._process(delta)

	camera.position = snake.position

	score_label.text = "Score: %d" % snake.segments_eaten

	_check_food_collision()

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


func _spawn_food() -> void:
	var small_shapes: Array = [
		FoodItem.FoodShape.RECTANGLE,
		FoodItem.FoodShape.PARALLELOGRAM,
		FoodItem.FoodShape.STAR_4,
	]
	var medium_shapes: Array = [
		FoodItem.FoodShape.STAR_5,
		FoodItem.FoodShape.CROSS,
	]
	var large_shapes: Array = [
		FoodItem.FoodShape.STAR_6,
	]

	for i: int in range(FOOD_COUNT):
		var food: FoodItem = FoodItem.new()

		var size: FoodItem.FoodSize
		var shape: FoodItem.FoodShape
		var roll: float = randf()
		if roll < 0.55:
			size = FoodItem.FoodSize.SMALL
			shape = small_shapes[randi() % small_shapes.size()]
		elif roll < 0.85:
			size = FoodItem.FoodSize.MEDIUM
			shape = medium_shapes[randi() % medium_shapes.size()]
		else:
			size = FoodItem.FoodSize.LARGE
			shape = large_shapes[randi() % large_shapes.size()]

		# Set up the food first so we know its actual radius for spacing.
		var temp_pos: Vector2 = Vector2(
			randf_range(FOOD_MARGIN, MAP_SIZE.x - FOOD_MARGIN),
			randf_range(FOOD_MARGIN, MAP_SIZE.y - FOOD_MARGIN),
		)
		food.setup(temp_pos, size, shape)

		# Try to find a non-overlapping position.
		var placed: bool = false
		for _attempt: int in range(MAX_PLACEMENT_ATTEMPTS):
			var pos: Vector2 = Vector2(
				randf_range(FOOD_MARGIN, MAP_SIZE.x - FOOD_MARGIN),
				randf_range(FOOD_MARGIN, MAP_SIZE.y - FOOD_MARGIN),
			)
			# Large/medium food can't spawn near the player start.
			if size != FoodItem.FoodSize.SMALL:
				if pos.distance_to(MAP_SIZE / 2.0) < SPAWN_SAFE_RADIUS:
					continue
			if _is_food_position_clear(pos, food.radius):
				food.position = pos
				placed = true
				break

		if not placed:
			# Use last attempted position rather than skipping.
			pass

		_food_container.add_child(food)

	total_food = FOOD_COUNT


func _is_food_position_clear(pos: Vector2, new_radius: float) -> bool:
	for child: Node in _food_container.get_children():
		if not child is FoodItem:
			continue
		var other: FoodItem = child as FoodItem
		var min_dist: float = new_radius + other.radius + FOOD_BUFFER
		if pos.distance_to(other.position) < min_dist:
			return false
	return true


func _check_food_collision() -> void:
	var head_pos: Vector2 = snake.position
	var head_r: float = snake.get_head_radius()
	var max_eatable: float = snake.get_max_eatable_size()

	for food: Node in _food_container.get_children():
		if not food is FoodItem:
			continue
		var f: FoodItem = food as FoodItem
		f.update_locked_state(max_eatable)

		var dist: float = head_pos.distance_to(f.position)
		if dist < head_r + f.radius * 0.5:
			if f.locked:
				# Too large to eat — die on impact.
				_end_game(false)
				return
			snake.grow(f.worth)
			_effects.emit_eat_burst(f.position, f.color)
			f.queue_free()
			total_food -= 1

			if total_food <= 0:
				_end_game(true)
			return


func _spawn_snake() -> void:
	snake = Snake.new()
	snake.position = MAP_SIZE / 2.0
	add_child(snake)


func _on_tier_changed(_new_tier: int) -> void:
	_effects.emit_tier_burst(snake.position, snake.get_tier_color())
	_effects.update_trail_color(snake.get_tier_color())
	# Camera shake.
	var tween: Tween = create_tween()
	tween.tween_property(camera, "offset", Vector2(3, 3), 0.05)
	tween.tween_property(camera, "offset", Vector2(-3, -3), 0.05)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.1)
	# Screen flash.
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(snake.get_tier_color(), 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(flash)
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(flash, "color:a", 0.0, 0.3)
	flash_tween.tween_callback(flash.queue_free)


func _end_game(cleared: bool) -> void:
	game_over = true
	snake.set_process(false)
	if not cleared:
		_effects.emit_death_shatter(snake.get_segment_positions(), snake.get_segments())
		snake.visible = false
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
