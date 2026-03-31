extends BaseGame


const MAP_SIZE: Vector2 = Vector2(3600, 6400)
const FOOD_COUNT: int = 120

var game_over: bool = false
var segments_eaten: int = 0
var total_food: int = 0

@onready var camera: Camera2D = $Camera2D
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var score_label: Label = $UI/ScoreLabel


func _ready() -> void:
	super._ready()


func _process(delta: float) -> void:
	if game_over:
		return
	super._process(delta)


func _on_pause_pressed() -> void:
	pause_menu.show_pause()
