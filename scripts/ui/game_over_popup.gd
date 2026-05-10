extends Control

signal restart_requested
signal exit_requested

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $PanelContainer/MarginContainer/VBoxContainer/MessageLabel
@onready var restart_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/RestartButton
@onready var exit_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/ExitButton

func _ready() -> void:
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	_update_language()

func _update_language() -> void:
	match GameManager.current_language:
		GameManager.Language.CHINESE:
			title_label.text = "游戏结束"
			message_label.text = "生命值耗尽，再试一次吧！"
			restart_button.text = "重新开始"
			exit_button.text = "退出"
		_:
			title_label.text = "Game Over"
			message_label.text = "Out of lives! Try again!"
			restart_button.text = "Restart"
			exit_button.text = "Exit"

func show_game_over() -> void:
	_update_language()
	visible = true
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	dim_overlay.color = Color(0, 0, 0, 0.0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.6), 0.3)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

	AudioManager.play_sfx("life_change")

func _on_restart_pressed() -> void:
	AudioManager.play_sfx("click")
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.0), 0.15)
	tween.chain().tween_callback(func():
		visible = false
		restart_requested.emit()
	)

func _on_exit_pressed() -> void:
	AudioManager.play_sfx("click")
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.0), 0.15)
	tween.chain().tween_callback(func():
		visible = false
		exit_requested.emit()
	)
