extends Control

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var panel: TextureRect = $TextureRect

func _ready() -> void:
	visible = false
	dim_overlay.gui_input.connect(_on_dim_overlay_input)

func show_help() -> void:
	visible = true
	var scale_dst = Vector2.ONE
	if OrientationManager.current_orientation == OrientationManager.Orientation.LANDSCAPE:
		panel.scale = Vector2(0.56, 0.56)
		scale_dst = Vector2(0.7, 0.7)
	else:
		panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	dim_overlay.color = Color(0, 0, 0, 0.0)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.8), 0.3)
	tween.tween_property(panel, "scale", scale_dst, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func hide_help() -> void:
	AudioManager.play_sfx("click")
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.0), 0.15)
	tween.chain().tween_callback(func():
		visible = false
	)

func _on_dim_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_help()
	elif event is InputEventScreenTouch and event.pressed:
		hide_help()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		hide_help()
		get_viewport().set_input_as_handled()
