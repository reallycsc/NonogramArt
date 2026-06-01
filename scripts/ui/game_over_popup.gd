extends Control

signal restart_requested
signal exit_requested
signal ad_reward_requested

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var panel: Panel = $PanelContainer
@onready var ad_reward_button: TextureButton = $PanelContainer/AdRewardButton
@onready var ad_reward_button_label: Label = $PanelContainer/AdRewardButton/Label

var _ad_reward_loading: bool = false

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	pass

func show_game_over() -> void:
	visible = true
	_ad_reward_loading = false
	ad_reward_button.disabled = false
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	dim_overlay.color = Color(0, 0, 0, 0.0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.8), 0.3)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

	AudioManager.play_sfx("game_over")

func set_ad_loading() -> void:
	_ad_reward_loading = true
	ad_reward_button.disabled = true
	ad_reward_button_label.text = tr("广告加载中...")

func _on_ad_reward_pressed() -> void:
	if _ad_reward_loading:
		return
	AudioManager.play_sfx("click")
	set_ad_loading()
	ad_reward_requested.emit()

func continue_after_ad() -> void:
	_ad_reward_loading = false
	ad_reward_button.disabled = true
	ad_reward_button_label.text = tr("已恢复生命")

func is_ad_loading() -> bool:
	return _ad_reward_loading

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
