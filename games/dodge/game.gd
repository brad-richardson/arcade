extends BaseGame


const PLAYER_SPEED: float = 600.0
const BLOCK_SIZE: Vector2 = Vector2(60, 60)
const BASE_FALL_SPEED: float = 400.0
const SPEED_INCREASE_RATE: float = 10.0
const MIN_SPAWN_INTERVAL: float = 0.3

var game_over: bool = false
var touch_target_x: float = -1.0

@onready var player: CharacterBody2D = $Player
@onready var score_label: Label = $ScoreLabel
@onready var spawn_timer: Timer = $SpawnTimer
@onready var pause_menu: CanvasLayer = $PauseMenu


func _ready() -> void:
	super._ready()
	var vp: Vector2 = get_viewport_rect().size
	player.position = Vector2(vp.x / 2.0, vp.y - 180.0)


func _process(delta: float) -> void:
	if game_over:
		return

	super._process(delta)
	score_label.text = "Score: %d" % int(time_played)

	_move_player(delta)
	_update_blocks(delta)


func _move_player(_delta: float) -> void:
	var direction: float = 0.0

	if Input.is_action_pressed("ui_left"):
		direction = -1.0
	elif Input.is_action_pressed("ui_right"):
		direction = 1.0

	if touch_target_x >= 0.0:
		var diff: float = touch_target_x - player.position.x
		if absf(diff) > 10.0:
			direction = signf(diff)
		else:
			direction = 0.0

	player.velocity = Vector2(direction * PLAYER_SPEED, 0.0)
	player.move_and_slide()

	var vp_width: float = get_viewport_rect().size.x
	player.position.x = clampf(player.position.x, 30.0, vp_width - 30.0)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			touch_target_x = touch.position.x
		else:
			touch_target_x = -1.0
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		touch_target_x = drag.position.x


func _update_blocks(delta: float) -> void:
	var fall_speed: float = BASE_FALL_SPEED + time_played * SPEED_INCREASE_RATE
	var vp_height: float = get_viewport_rect().size.y
	for block: Node in get_tree().get_nodes_in_group("blocks"):
		block.position.y += fall_speed * delta
		if block.position.y > vp_height + 100.0:
			block.queue_free()


func _on_spawn_timer_timeout() -> void:
	if game_over:
		return
	var new_interval: float = maxf(MIN_SPAWN_INTERVAL, 1.0 - time_played * 0.02)
	spawn_timer.wait_time = new_interval
	_spawn_block()


func _spawn_block() -> void:
	var block: Area2D = Area2D.new()
	block.add_to_group("blocks")

	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect_shape: RectangleShape2D = RectangleShape2D.new()
	rect_shape.size = BLOCK_SIZE
	shape.shape = rect_shape
	block.add_child(shape)

	var visual: ColorRect = ColorRect.new()
	visual.size = BLOCK_SIZE
	visual.position = -BLOCK_SIZE / 2.0
	visual.color = Color(1.0, 0.3, 0.3, 1.0)
	block.add_child(visual)

	var vp_width: float = get_viewport_rect().size.x
	var margin: float = BLOCK_SIZE.x / 2.0
	block.position = Vector2(
		randf_range(margin, vp_width - margin),
		-50.0
	)

	block.body_entered.connect(_on_block_hit)
	add_child(block)


func _on_block_hit(_body: Node2D) -> void:
	if game_over:
		return
	_game_over()


func _game_over() -> void:
	game_over = true
	spawn_timer.stop()

	var coins_earned: int = award_coins()

	var vp: Vector2 = get_viewport_rect().size
	var label_size: Vector2 = Vector2(500, 200)
	var game_over_label: Label = Label.new()
	game_over_label.text = "Game Over!\nScore: %d\nCoins: +%d" % [int(time_played), coins_earned]
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_size_override("font_size", 48)
	game_over_label.size = label_size
	game_over_label.position = (vp - label_size) / 2.0
	add_child(game_over_label)

	await get_tree().create_timer(2.0).timeout
	SceneTransition.go_to_hub()


func _on_pause_pressed() -> void:
	pause_menu.show_pause()
