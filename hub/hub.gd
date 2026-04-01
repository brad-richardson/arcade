extends Control


@onready var game_grid: GridContainer = %GameGrid

var game_card_scene: PackedScene = preload("res://hub/game_card.tscn")


func _ready() -> void:
	if GameRegistry.get_games().size() > 0:
		_populate_games()
	else:
		GameRegistry.games_loaded.connect(_populate_games)


func _populate_games() -> void:
	for child in game_grid.get_children():
		child.queue_free()

	var games: Array = GameRegistry.get_games()
	var index: int = 0
	for game_data: Dictionary in games:
		var card: PanelContainer = game_card_scene.instantiate()
		game_grid.add_child(card)
		card.setup(game_data, index)
		index += 1
