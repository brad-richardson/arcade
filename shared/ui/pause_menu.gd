extends CanvasLayer
## Reusable pause menu overlay.
## Add as a child scene in any game to provide pause/resume/quit functionality.

@onready var overlay: ColorRect = $Overlay


func show_pause() -> void:
	get_tree().paused = true
	overlay.visible = true


func _on_resume_pressed() -> void:
	get_tree().paused = false
	overlay.visible = false


func _on_quit_pressed() -> void:
	get_tree().paused = false
	overlay.visible = false
	SceneTransition.go_to_hub()
