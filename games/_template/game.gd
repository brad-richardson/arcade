extends BaseGame


func _on_pause_pressed() -> void:
	SceneTransition.go_to_hub()


func _exit_game() -> void:
	award_coins()
	SceneTransition.go_to_hub()
