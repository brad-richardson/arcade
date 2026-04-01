extends CanvasLayer
## Shared game over screen overlay.
## Shows title, score, coins earned, and play again / quit buttons.
## Usage: call show_game_over("Game Over!", "Score: 42", 12)

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Overlay/Panel
@onready var title_label: Label = $Overlay/Panel/VBoxContainer/TitleLabel
@onready var score_label: Label = $Overlay/Panel/VBoxContainer/ScoreLabel
@onready var coins_label: Label = $Overlay/Panel/VBoxContainer/CoinsLabel
@onready var play_again_button: Button = $Overlay/Panel/VBoxContainer/PlayAgainButton
@onready var hub_button: Button = $Overlay/Panel/VBoxContainer/HubButton


func _ready() -> void:
	overlay.visible = false
	overlay.modulate.a = 0.0
	panel.pivot_offset = panel.size / 2.0


func show_game_over(title: String, score_text: String, coins: int) -> void:
	get_tree().paused = true
	title_label.text = title
	score_label.text = score_text
	coins_label.text = "Coins: +%d" % coins
	overlay.visible = true

	# Animate overlay fade in and panel slide down.
	panel.position.y -= 60.0
	var start_y: float = panel.position.y
	var target_y: float = start_y + 60.0

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position:y", target_y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _on_play_again_pressed() -> void:
	get_tree().paused = false
	overlay.visible = false
	get_tree().reload_current_scene()


func _on_hub_pressed() -> void:
	get_tree().paused = false
	overlay.visible = false
	SceneTransition.go_to_hub()
