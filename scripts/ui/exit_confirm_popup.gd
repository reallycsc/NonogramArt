extends Control

signal confirmed
signal cancelled

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var panel: Panel = $PanelContainer

func _ready() -> void:
	visible = false

func show_popup(message: String = tr("确定要退出游戏吗？")) -> void:
	var message_label = $PanelContainer/MessageLabel
	message_label.text = message
	visible = true
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	dim_overlay.color = Color(0, 0, 0, 0.0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.8), 0.3)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func _hide_with_callback(callback: Callable) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.0), 0.15)
	tween.chain().tween_callback(func():
		visible = false
		callback.call()
	)

func _on_confirm_pressed() -> void:
	AudioManager.play_sfx("click")
	_hide_with_callback(func(): confirmed.emit())

func _on_cancel_pressed() -> void:
	AudioManager.play_sfx("click")
	_hide_with_callback(func(): cancelled.emit())
