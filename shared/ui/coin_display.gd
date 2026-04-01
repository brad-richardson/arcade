extends HBoxContainer
## Small HUD widget that displays the current coin balance.
## Shows a yellow circle icon next to the number.
## Connects to CurrencyManager.coins_changed to stay in sync.

@onready var balance_label: Label = $BalanceLabel


func _ready() -> void:
	CurrencyManager.coins_changed.connect(update_display)
	update_display()


func update_display(new_balance: int = -1) -> void:
	if new_balance < 0:
		new_balance = CurrencyManager.get_balance()
	balance_label.text = str(new_balance)
