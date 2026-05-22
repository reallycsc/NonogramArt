extends TextureButton

signal badge_clicked(chapter_id: String)

@onready var _progress_label: Label = $ProgressLabel

var chapter_id: String = ""
var chapter_name: String = ""
var completed_count: int = 0
var total_count: int = 0
var is_activated: bool = false

var _badge_tex: Texture2D = null
var _badge_grey_tex: Texture2D = null
var _hover_tween: Tween = null
var _click_tween: Tween = null
var _pulse_tween: Tween = null

const HOVER_SCALE := Vector2(1.15, 1.15)
const NORMAL_SCALE := Vector2(1.0, 1.0)
const PRESS_SCALE := Vector2(0.9, 0.9)
const HOVER_MODULATE := Color(1.3, 1.3, 1.3, 1.0)
const NORMAL_MODULATE := Color.WHITE
const PRESS_MODULATE := Color(0.85, 0.85, 0.85, 1.0)


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	resized.connect(_on_resized)


func _on_resized() -> void:
	pivot_offset = size * 0.5


func setup(p_chapter_id: String, p_chapter_name: String, p_badge_tex: Texture2D, p_badge_grey_tex: Texture2D, p_completed: int, p_total: int) -> void:
	chapter_id = p_chapter_id
	chapter_name = p_chapter_name
	_badge_tex = p_badge_tex
	_badge_grey_tex = p_badge_grey_tex
	completed_count = p_completed
	total_count = p_total
	is_activated = completed_count >= total_count and total_count > 0

	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	ignore_texture_size = true
	custom_minimum_size = Vector2(64, 64)

	_apply_visual_state()
	_update_progress_label()


func update_progress(p_completed: int, p_total: int) -> void:
	completed_count = p_completed
	total_count = p_total
	var was_activated = is_activated
	is_activated = completed_count >= total_count and total_count > 0

	_apply_visual_state()
	_update_progress_label()

	if is_activated and not was_activated:
		_play_activate_animation()


func increment_count() -> void:
	if completed_count < total_count:
		completed_count += 1
		var was_activated = is_activated
		is_activated = completed_count >= total_count and total_count > 0
		_apply_visual_state()
		_update_progress_label()
		if is_activated and not was_activated:
			_play_activate_animation()


func _apply_visual_state() -> void:
	if is_activated and _badge_tex:
		texture_normal = _badge_tex
		texture_pressed = _badge_tex
		texture_hover = _badge_tex
		texture_disabled = _badge_tex
		_progress_label.hide()
	else:
		var tex = _badge_grey_tex if _badge_grey_tex else _badge_tex
		texture_normal = tex
		texture_pressed = tex
		texture_hover = tex
		texture_disabled = tex
		if completed_count == 0:
			_progress_label.hide()
		else:
			_progress_label.show()


func _update_progress_label() -> void:
	if _progress_label:
		_progress_label.text = "%d/%d" % [completed_count, total_count]


func _on_mouse_entered() -> void:
	if not is_activated:
		return
	if button_pressed:
		return
	_kill_hover_tween()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", HOVER_SCALE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hover_tween.parallel().tween_property(self, "modulate", HOVER_MODULATE, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	if not is_activated:
		return
	_kill_hover_tween()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", NORMAL_SCALE, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_hover_tween.parallel().tween_property(self, "modulate", NORMAL_MODULATE, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_button_down() -> void:
	if not is_activated:
		return
	_kill_click_tween()
	_click_tween = create_tween()
	_click_tween.tween_property(self, "scale", PRESS_SCALE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_click_tween.parallel().tween_property(self, "modulate", PRESS_MODULATE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _on_button_up() -> void:
	if not is_activated:
		return
	_kill_click_tween()
	_click_tween = create_tween()
	_click_tween.tween_property(self, "scale", HOVER_SCALE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_click_tween.parallel().tween_property(self, "modulate", HOVER_MODULATE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	badge_clicked.emit(chapter_id)


func _play_activate_animation() -> void:
	_kill_pulse_tween()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(self, "scale", NORMAL_SCALE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func play_receive_light_animation() -> void:
	_kill_pulse_tween()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_pulse_tween.parallel().tween_property(self, "scale", Vector2(1.25, 1.25), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(self, "modulate", NORMAL_MODULATE, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pulse_tween.parallel().tween_property(self, "scale", NORMAL_SCALE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _kill_hover_tween() -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = null


func _kill_click_tween() -> void:
	if _click_tween and _click_tween.is_valid():
		_click_tween.kill()
	_click_tween = null


func _kill_pulse_tween() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null


func get_global_center() -> Vector2:
	return global_position + size * 0.5
