extends BaseGame
## SkyTree — Grow a magical tree skyward, steering around obstacles.
## Inspired by Prune × Dolphin Olympics.

enum State { SEED_SELECT, GROWING, GAME_OVER }

const SEEDS: Array[Dictionary] = [
	{
		"name": "Oakhart",
		"description": "Sturdy & forgiving",
		"color": Color(0.35, 0.55, 0.2),
		"glow_color": Color(0.5, 0.9, 0.3),
		"growth_speed": 120.0,
		"drift_strength": 0.8,
		"trunk_width": 14.0,
		"collision_forgiveness": 0.7,
		"can_burn": false,
		"score_multiplier": 1.0,
	},
	{
		"name": "Willowwisp",
		"description": "Fast & flexible",
		"color": Color(0.1, 0.6, 0.55),
		"glow_color": Color(0.2, 1.0, 0.9),
		"growth_speed": 160.0,
		"drift_strength": 1.5,
		"trunk_width": 8.0,
		"collision_forgiveness": 1.0,
		"can_burn": false,
		"score_multiplier": 1.0,
	},
	{
		"name": "Emberthorn",
		"description": "Burns through 1 obstacle",
		"color": Color(0.7, 0.3, 0.05),
		"glow_color": Color(1.0, 0.6, 0.1),
		"growth_speed": 130.0,
		"drift_strength": 1.0,
		"trunk_width": 11.0,
		"collision_forgiveness": 1.0,
		"can_burn": true,
		"score_multiplier": 1.0,
	},
	{
		"name": "Starbloom",
		"description": "Slow but 2× score",
		"color": Color(0.5, 0.2, 0.8),
		"glow_color": Color(0.8, 0.5, 1.0),
		"growth_speed": 100.0,
		"drift_strength": 0.6,
		"trunk_width": 10.0,
		"collision_forgiveness": 1.0,
		"can_burn": false,
		"score_multiplier": 2.0,
	},
]

const START_Y: float = 600.0
const CARD_Y: float = 700.0
const CARD_WIDTH: float = 140.0
const CARD_HEIGHT: float = 180.0
const CARD_GAP: float = 15.0
const PLANT_BUTTON_Y: float = 940.0
const MILESTONE_INTERVAL: float = 1000.0

# Background color zones (by height in pixels).
const BG_ZONES: Array[Dictionary] = [
	{"height": 0.0, "color": Color(0.15, 0.1, 0.08)},
	{"height": 500.0, "color": Color(0.18, 0.35, 0.15)},
	{"height": 2000.0, "color": Color(0.33, 0.57, 0.82)},
	{"height": 4000.0, "color": Color(0.42, 0.25, 0.63)},
	{"height": 7000.0, "color": Color(0.04, 0.04, 0.12)},
]

var state: int = State.SEED_SELECT
var selected_seed: int = -1
var tree: SkyTree
var obstacles: TreeObstacles
var effects: TreeEffects
var height_score: float = 0.0
var display_score: int = 0
var base_multiplier: float = 1.0
var in_sunbeam: bool = false
var has_burned: bool = false
var _next_milestone: float = MILESTONE_INTERVAL
var _camera_initialized: bool = false

@onready var camera: Camera2D = $Camera2D
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var score_label: Label = $UI/ScoreLabel
@onready var multiplier_label: Label = $UI/MultiplierLabel


func _ready() -> void:
	super._ready()
	# Start camera at seed select position.
	camera.position = Vector2(0.0, START_Y)
	camera.make_current()
	queue_redraw()


func _process(delta: float) -> void:
	if state == State.GROWING:
		super._process(delta)
		_update_growing(delta)
	elif state == State.SEED_SELECT:
		queue_redraw()


func _update_growing(delta: float) -> void:
	tree.grow(delta)
	obstacles.update_camera(camera.position.y, get_viewport_rect().size.y)
	obstacles.spawn_tick(delta, tree.get_height())
	effects.position = Vector2.ZERO

	# Camera follow — smooth vertical, fixed horizontal.
	var target_y: float = tree.tip_position.y - 200.0
	if not _camera_initialized:
		camera.position.y = target_y
		_camera_initialized = true
	else:
		camera.position.y = lerpf(camera.position.y, target_y, 5.0 * delta)
	camera.position.x = 0.0

	# Scoring.
	height_score = tree.get_height()
	display_score = int(height_score / 10.0)
	score_label.text = "Height: %dm" % display_score

	# Check sunbeam bonus.
	in_sunbeam = false
	for obs: Dictionary in obstacles.get_active_obstacles():
		if obs["type"] == TreeObstacles.TYPE_SUNBEAM:
			var half: Vector2 = obs["size"] / 2.0
			if tree.tip_position.x > obs["pos"].x - half.x \
					and tree.tip_position.x < obs["pos"].x + half.x \
					and tree.tip_position.y > obs["pos"].y - half.y \
					and tree.tip_position.y < obs["pos"].y + half.y:
				in_sunbeam = true
				break

	var current_mult: float = base_multiplier * (1.5 if in_sunbeam else 1.0)
	if current_mult > 1.0:
		multiplier_label.text = "×%.1f" % current_mult
	else:
		multiplier_label.text = ""

	# Milestones.
	if height_score >= _next_milestone:
		_next_milestone += MILESTONE_INTERVAL
		effects.emit_milestone_burst(tree.tip_position, tree.glow_color)
		# Camera shake.
		var tween: Tween = create_tween()
		tween.tween_property(camera, "offset", Vector2(3, 3), 0.05)
		tween.tween_property(camera, "offset", Vector2(-3, -3), 0.05)
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.1)

	# Collision checks.
	if tree.check_bounds():
		_end_game()
		return

	var hit: int = tree.check_obstacle_collision(obstacles.get_active_obstacles())
	# Always clear slow first; re-apply only if still in a cloud.
	tree.clear_slow()
	if hit == TreeObstacles.TYPE_STONE:
		if tree.can_burn and not has_burned:
			has_burned = true
			effects.emit_milestone_burst(tree.tip_position, Color(1.0, 0.4, 0.0))
		else:
			_end_game()
			return
	elif hit == TreeObstacles.TYPE_CLOUD:
		tree.apply_slow(0.5)
	elif hit == TreeObstacles.TYPE_WIND:
		# Find which wind obstacle we hit to get direction.
		for obs: Dictionary in obstacles.get_active_obstacles():
			if obs["type"] == TreeObstacles.TYPE_WIND:
				var half: Vector2 = obs["size"] / 2.0
				if tree.tip_position.x > obs["pos"].x - half.x \
						and tree.tip_position.x < obs["pos"].x + half.x \
						and tree.tip_position.y > obs["pos"].y - half.y \
						and tree.tip_position.y < obs["pos"].y + half.y:
					tree.apply_wind(obs["wind_dir"] * 200.0)
					break

	queue_redraw()


func _draw() -> void:
	# Background — full viewport color based on height.
	var vp: Vector2 = get_viewport_rect().size
	var bg_color: Color = _get_bg_color(tree.get_height() if tree else 0.0)
	var cam_pos: Vector2 = camera.position
	var bg_rect: Rect2 = Rect2(
		cam_pos.x - vp.x / 2.0, cam_pos.y - vp.y / 2.0, vp.x, vp.y
	)
	draw_rect(bg_rect, bg_color)

	# Stars in space zone.
	if tree and tree.get_height() > 4000.0:
		var star_seed: int = 42
		for i: int in range(30):
			var sx: float = fmod(float(i * 137 + star_seed), vp.x) - vp.x / 2.0 + cam_pos.x
			var sy: float = cam_pos.y - vp.y / 2.0 + fmod(float(i * 251 + star_seed), vp.y)
			var star_alpha: float = 0.3 + sin(time_played * 2.0 + float(i)) * 0.2
			draw_circle(Vector2(sx, sy), 1.5, Color(1.0, 1.0, 1.0, star_alpha))

	# Seed selection UI.
	if state == State.SEED_SELECT:
		_draw_seed_select(vp, cam_pos)


func _draw_seed_select(vp: Vector2, cam_pos: Vector2) -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 16
	var small_size: int = 12
	var title_size: int = 24

	# Title.
	var title_text: String = "Choose Your Seed"
	var title_pos: Vector2 = Vector2(
		cam_pos.x - font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x / 2.0,
		cam_pos.y - vp.y / 2.0 + CARD_Y - 40.0
	)
	draw_string(font, title_pos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color.WHITE)

	# Seed selection cards.
	var total_width: float = SEEDS.size() * CARD_WIDTH + (SEEDS.size() - 1) * CARD_GAP
	var start_x: float = cam_pos.x - total_width / 2.0

	for i: int in range(SEEDS.size()):
		var seed_data: Dictionary = SEEDS[i]
		var card_x: float = start_x + i * (CARD_WIDTH + CARD_GAP)
		var card_y: float = cam_pos.y - vp.y / 2.0 + CARD_Y
		var card_rect: Rect2 = Rect2(card_x, card_y, CARD_WIDTH, CARD_HEIGHT)

		# Card background.
		var bg: Color = Color(0.12, 0.12, 0.18)
		if i == selected_seed:
			bg = Color(0.2, 0.2, 0.3)
		draw_rect(card_rect, bg)

		# Selection highlight border.
		var border_color: Color = seed_data["glow_color"] if i == selected_seed else Color(0.3, 0.3, 0.35)
		draw_rect(card_rect, border_color, false, 3.0 if i == selected_seed else 1.0)

		# Seed orb preview.
		var orb_center: Vector2 = Vector2(card_x + CARD_WIDTH / 2.0, card_y + 50.0)
		draw_circle(orb_center, 25.0, seed_data["color"])
		draw_circle(orb_center, 18.0, Color(seed_data["glow_color"], 0.5))
		draw_circle(orb_center, 10.0, Color(seed_data["glow_color"], 0.8))

		# Seed name.
		var name_text: String = seed_data["name"]
		var name_w: float = font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, Vector2(card_x + (CARD_WIDTH - name_w) / 2.0, card_y + 100.0), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

		# Seed description.
		var desc_text: String = seed_data["description"]
		var desc_w: float = font.get_string_size(desc_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_size).x
		draw_string(font, Vector2(card_x + (CARD_WIDTH - desc_w) / 2.0, card_y + 120.0), desc_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_size, Color(1.0, 1.0, 1.0, 0.6))

	# Plant button (only if seed selected).
	if selected_seed >= 0:
		var btn_w: float = 180.0
		var btn_h: float = 50.0
		var btn_rect: Rect2 = Rect2(
			cam_pos.x - btn_w / 2.0,
			cam_pos.y - vp.y / 2.0 + PLANT_BUTTON_Y,
			btn_w, btn_h
		)
		var btn_color: Color = SEEDS[selected_seed]["glow_color"]
		draw_rect(btn_rect, Color(btn_color, 0.3))
		draw_rect(btn_rect, btn_color, false, 2.0)

		# Button label.
		var plant_text: String = "Plant"
		var plant_w: float = font.get_string_size(plant_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
		draw_string(font, Vector2(btn_rect.position.x + (btn_w - plant_w) / 2.0, btn_rect.position.y + 33.0), plant_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, btn_color)

	# Tutorial hint.
	var hint_text: String = "Drag left/right to steer"
	var hint_w: float = font.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_size).x
	var hint_y: float = cam_pos.y - vp.y / 2.0 + PLANT_BUTTON_Y + 80.0
	draw_string(font, Vector2(cam_pos.x - hint_w / 2.0, hint_y), hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_size, Color(1.0, 1.0, 1.0, 0.35))


func _input(event: InputEvent) -> void:
	if state == State.SEED_SELECT:
		_handle_seed_select_input(event)
	elif state == State.GROWING:
		_handle_growing_input(event)


func _handle_seed_select_input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	var pressed: bool = false
	var pos: Vector2 = Vector2.ZERO

	if event is InputEventScreenTouch:
		pressed = event.pressed
		pos = event.position
	elif event is InputEventMouseButton:
		pressed = event.pressed
		pos = event.position

	if not pressed:
		return

	var vp: Vector2 = get_viewport_rect().size

	# Check plant button tap.
	if selected_seed >= 0:
		var btn_w: float = 180.0
		var btn_h: float = 50.0
		var btn_rect: Rect2 = Rect2(vp.x / 2.0 - btn_w / 2.0, PLANT_BUTTON_Y, btn_w, btn_h)
		if btn_rect.has_point(pos):
			_start_game()
			return

	# Check seed card taps.
	var total_width: float = SEEDS.size() * CARD_WIDTH + (SEEDS.size() - 1) * CARD_GAP
	var start_x: float = vp.x / 2.0 - total_width / 2.0

	for i: int in range(SEEDS.size()):
		var card_rect: Rect2 = Rect2(
			start_x + i * (CARD_WIDTH + CARD_GAP),
			CARD_Y,
			CARD_WIDTH, CARD_HEIGHT
		)
		if card_rect.has_point(pos):
			selected_seed = i
			score_label.text = SEEDS[i]["name"]
			multiplier_label.text = SEEDS[i]["description"]
			queue_redraw()
			return


func _handle_growing_input(event: InputEvent) -> void:
	var pos_x: float = -1.0

	if event is InputEventScreenTouch:
		if event.pressed:
			pos_x = event.position.x
		elif tree:
			# Finger lifted: stop steering.
			tree.steer_direction = 0.0
	elif event is InputEventScreenDrag:
		pos_x = event.position.x
	elif event is InputEventMouseButton:
		if event.pressed:
			pos_x = event.position.x
		elif event.button_index == MOUSE_BUTTON_LEFT and tree:
			# Left mouse button released: stop steering.
			tree.steer_direction = 0.0
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			pos_x = event.position.x

	if pos_x >= 0.0 and tree:
		var vp_center: float = get_viewport_rect().size.x / 2.0
		var offset: float = (pos_x - vp_center) / vp_center
		tree.steer_direction = clampf(offset, -1.0, 1.0)

	# Keyboard fallback.
	if event is InputEventKey:
		if Input.is_action_pressed("ui_left"):
			tree.steer_direction = -1.0
		elif Input.is_action_pressed("ui_right"):
			tree.steer_direction = 1.0
		else:
			tree.steer_direction = 0.0


func _start_game() -> void:
	state = State.GROWING
	var seed_config: Dictionary = SEEDS[selected_seed]
	base_multiplier = seed_config.get("score_multiplier", 1.0)
	has_burned = false

	# Create tree.
	tree = SkyTree.new()
	tree.position = Vector2(0.0, START_Y)
	add_child(tree)
	tree.setup(seed_config)

	# Create obstacles.
	obstacles = TreeObstacles.new()
	add_child(obstacles)

	# Create effects.
	effects = TreeEffects.new()
	add_child(effects)
	effects.set_trail_source(tree)

	score_label.text = "Height: 0m"
	multiplier_label.text = ""

	_camera_initialized = false


func _end_game() -> void:
	state = State.GAME_OVER
	tree.die()
	effects.emit_death_burst(tree.tip_position, tree.glow_color)

	var final_mult: float = base_multiplier * (1.5 if in_sunbeam else 1.0)
	var coins_earned: int = int(float(display_score) * coin_rate * final_mult)
	if coins_earned > 0:
		CurrencyManager.add_coins(coins_earned)

	var vp: Vector2 = get_viewport_rect().size
	var label_size: Vector2 = Vector2(500, 200)
	var end_label: Label = Label.new()
	end_label.text = "Game Over!\nHeight: %dm\nCoins: +%d" % [display_score, coins_earned]
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_label.add_theme_font_size_override("font_size", 48)
	end_label.size = label_size
	end_label.position = (vp - label_size) / 2.0
	$UI.add_child(end_label)

	await get_tree().create_timer(2.5).timeout
	SceneTransition.go_to_hub()


func _on_pause_pressed() -> void:
	if state == State.GROWING:
		pause_menu.show_pause()


func _get_bg_color(height: float) -> Color:
	if BG_ZONES.size() == 0:
		return Color.BLACK
	if height <= BG_ZONES[0]["height"]:
		return BG_ZONES[0]["color"]

	for i: int in range(1, BG_ZONES.size()):
		if height < BG_ZONES[i]["height"]:
			var prev: Dictionary = BG_ZONES[i - 1]
			var curr: Dictionary = BG_ZONES[i]
			var t: float = (height - prev["height"]) / (curr["height"] - prev["height"])
			return prev["color"].lerp(curr["color"], t)

	return BG_ZONES[BG_ZONES.size() - 1]["color"]
