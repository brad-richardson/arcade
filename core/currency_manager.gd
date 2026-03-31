extends Node

signal coins_changed(new_balance: int)

var _balance: int = 0


func _ready() -> void:
	_balance = SaveManager.load_value("currency", "coins", 0)


func add_coins(amount: int) -> void:
	_balance += amount
	SaveManager.save_value("currency", "coins", _balance)
	coins_changed.emit(_balance)


func get_balance() -> int:
	return _balance
