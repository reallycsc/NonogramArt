extends Control

signal closed

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var bgm_label: Label = $PanelContainer/MarginContainer/VBoxContainer/BGMContainer/BGMLabel
@onready var bgm_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/BGMContainer/BGMSlider
@onready var bgm_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/BGMContainer/BGMValueLabel
@onready var sfx_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SFXContainer/SFXLabel
@onready var sfx_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/SFXContainer/SFXSlider
@onready var sfx_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SFXContainer/SFXValueLabel
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/CloseButton

func _ready() -> void:
	visible = false
	bgm_slider.value = AudioManager.bgm_volume * 100.0
	sfx_slider.value = AudioManager.sfx_volume * 100.0
	_update_value_labels()
	bgm_slider.value_changed.connect(_on_bgm_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_value_changed)
	close_button.pressed.connect(_on_close_pressed)
	dim_overlay.gui_input.connect(_on_dim_overlay_input)
	AudioManager.bgm_volume_changed.connect(_on_bgm_volume_changed)
	AudioManager.sfx_volume_changed.connect(_on_sfx_volume_changed)
	_update_language()

func _update_language() -> void:
	match GameManager.current_language:
		GameManager.Language.CHINESE:
			title_label.text = "设置"
			bgm_label.text = "音乐"
			sfx_label.text = "音效"
			close_button.text = "关闭"
		_:
			title_label.text = "Settings"
			bgm_label.text = "Music"
			sfx_label.text = "SFX"
			close_button.text = "Close"

func _update_value_labels() -> void:
	if bgm_value_label:
		bgm_value_label.text = "%d%%" % int(bgm_slider.value)
	if sfx_value_label:
		sfx_value_label.text = "%d%%" % int(sfx_slider.value)

func show_settings() -> void:
	if visible:
		return
	bgm_slider.value = AudioManager.bgm_volume * 100.0
	sfx_slider.value = AudioManager.sfx_volume * 100.0
	_update_value_labels()
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
	AudioManager.play_sfx("click")

func hide_settings() -> void:
	AudioManager.play_sfx("click")
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.0), 0.15)
	tween.chain().tween_callback(func():
		visible = false
		closed.emit()
	)

func _on_dim_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close_pressed()

func _on_bgm_value_changed(value: float) -> void:
	AudioManager.bgm_volume = value / 100.0
	_update_value_labels()

func _on_sfx_value_changed(value: float) -> void:
	AudioManager.sfx_volume = value / 100.0
	AudioManager.play_sfx("click")
	_update_value_labels()

func _on_bgm_volume_changed(value: float) -> void:
	if bgm_slider:
		bgm_slider.value = value * 100.0
	_update_value_labels()

func _on_sfx_volume_changed(value: float) -> void:
	if sfx_slider:
		sfx_slider.value = value * 100.0
	_update_value_labels()

func _on_close_pressed() -> void:
	GameManager.settings["bgm_volume"] = AudioManager.bgm_volume
	GameManager.settings["sfx_volume"] = AudioManager.sfx_volume
	GameManager.save_game()
	hide_settings()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_on_close_pressed()
		get_viewport().set_input_as_handled()
