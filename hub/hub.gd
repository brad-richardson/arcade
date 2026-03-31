extends Control


@onready var coin_display: Label = %CoinDisplay
@onready var game_grid: GridContainer = %GameGrid

var game_card_scene: PackedScene = preload("res://hub/game_card.tscn")


func _ready() -> void:
	if GameRegistry.get_games().size() > 0:
		_populate_games()
	else:
		GameRegistry.games_loaded.connect(_populate_games)

	_update_coin_display()
	CurrencyManager.coins_changed.connect(_update_coin_display)


func _populate_games() -> void:
	for child in game_grid.get_children():
		child.queue_free()

	var games: Array = GameRegistry.get_games()
	for game_data: Dictionary in games:
		var card: PanelContainer = game_card_scene.instantiate()
		game_grid.add_child(card)
		card.setup(game_data)


func _update_coin_display(_new_balance: int = 0) -> void:
	coin_display.text = "Coins: %d" % CurrencyManager.get_balance()
