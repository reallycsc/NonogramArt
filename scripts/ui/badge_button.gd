extends TextureButton

var chapter_id: String = ""
var chapter_name: String = ""
var completed_count: int = 0
var total_count: int = 0
var is_activated: bool = false

var _badge_tex: Texture2D = null
var _badge_grey_tex: Texture2D = null
var _badge_icon_path: String = ""
var _hover_tween: Tween = null
var _click_tween: Tween = null
var _pulse_tween: Tween = null
var _overlay: Control = null
var _overlay_badge: TextureRect = null
var _overlay_tween: Tween = null
var _is_showing_overlay: bool = false
var _overlay_canvas: CanvasLayer = null
var _video_player: VideoStreamPlayer = null
var _sub_viewport: SubViewport = null

const HOVER_SCALE := Vector2(1.15, 1.15)
const NORMAL_SCALE := Vector2(1.0, 1.0)
const PRESS_SCALE := Vector2(0.9, 0.9)
const HOVER_MODULATE := Color(1.3, 1.3, 1.3, 1.0)
const NORMAL_MODULATE := Color.WHITE
const PRESS_MODULATE := Color(0.85, 0.85, 0.85, 1.0)
const OVERLAY_BADGE_SIZE := Vector2(512, 512)


func _ready() -> void:
	add_to_group("badge_buttons")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	resized.connect(_on_resized)


func _exit_tree() -> void:
	_kill_hover_tween()
	_kill_click_tween()
	_kill_pulse_tween()
	_kill_overlay_tween()
	_cleanup_overlay()


func _on_resized() -> void:
	pivot_offset = size * 0.5


func setup(p_chapter_id: String, p_chapter_name: String, p_badge_tex: Texture2D, p_badge_grey_tex: Texture2D, p_completed: int, p_total: int, p_badge_icon_path: String = "") -> void:
	chapter_id = p_chapter_id
	chapter_name = p_chapter_name
	_badge_tex = p_badge_tex
	_badge_grey_tex = p_badge_grey_tex
	_badge_icon_path = p_badge_icon_path
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
		_hide_progress_label()
	else:
		var tex = _badge_grey_tex if _badge_grey_tex else _badge_tex
		texture_normal = tex
		texture_pressed = tex
		texture_hover = tex
		texture_disabled = tex
		if completed_count == 0:
			_hide_progress_label()
		else:
			_show_progress_label()


func _hide_progress_label() -> void:
	var label = get_node_or_null("ProgressLabel")
	if label:
		label.hide()


func _show_progress_label() -> void:
	var label = get_node_or_null("ProgressLabel")
	if label:
		label.show()


func _update_progress_label() -> void:
	var label = get_node_or_null("ProgressLabel")
	if label:
		label.text = "%d/%d" % [completed_count, total_count]


func _on_mouse_entered() -> void:
	if not is_activated:
		return
	if button_pressed:
		return
	if _is_showing_overlay:
		return
	_kill_hover_tween()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", HOVER_SCALE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hover_tween.parallel().tween_property(self, "modulate", HOVER_MODULATE, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	if not is_activated:
		return
	if _is_showing_overlay:
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
	_click_tween.tween_property(self, "scale", NORMAL_SCALE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_click_tween.parallel().tween_property(self, "modulate", NORMAL_MODULATE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_show_badge_overlay()


func _show_badge_overlay() -> void:
	if _is_showing_overlay:
		return
	if not _badge_tex:
		return
	_is_showing_overlay = true

	var video_path = _get_badge_video_path()
	if video_path != "" and ResourceLoader.exists(video_path):
		_show_video_overlay(video_path)
	else:
		_show_static_overlay()


func _get_badge_video_path() -> String:
	if _badge_icon_path == "":
		return ""
	var video_path = _badge_icon_path.get_basename() + ".ogv"
	return video_path


func _show_video_overlay(video_path: String) -> void:
	var vp_size = get_viewport().get_visible_rect().size
	var center = vp_size * 0.5
	var video_size = Vector2(512, 512)
	var origin_center = get_global_center()

	_overlay_canvas = CanvasLayer.new()
	_overlay_canvas.layer = 100

	_overlay = Control.new()
	_overlay.name = "BadgeOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.gui_input.connect(_on_overlay_input)

	var black_bg = ColorRect.new()
	black_bg.name = "BlackBg"
	black_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_bg.color = Color(0, 0, 0, 0.0)
	black_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(black_bg)

	_sub_viewport = SubViewport.new()
	_sub_viewport.name = "VideoSubViewport"
	_sub_viewport.size = video_size
	_sub_viewport.transparent_bg = false
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	_video_player = VideoStreamPlayer.new()
	_video_player.name = "BadgeVideo"
	_video_player.position = Vector2.ZERO
	_video_player.size = video_size
	_video_player.expand = true
	_video_player.autoplay = true
	_video_player.loop = true

	var video_stream = load(video_path)
	if video_stream:
		_video_player.stream = video_stream

	_sub_viewport.add_child(_video_player)
	_overlay_canvas.add_child(_sub_viewport)

	_overlay_badge = TextureRect.new()
	_overlay_badge.name = "VideoRect"
	_overlay_badge.texture = _sub_viewport.get_texture()
	_overlay_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_overlay_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay_badge.size = video_size
	_overlay_badge.position = origin_center - video_size * 0.5
	_overlay_badge.pivot_offset = video_size * 0.5
	_overlay_badge.scale = Vector2(size.x / video_size.x, size.y / video_size.y)
	_overlay_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var chroma_mat = ShaderMaterial.new()
	chroma_mat.shader = preload("res://shaders/chroma_key.gdshader")
	chroma_mat.set_shader_parameter("threshold", 0.85)
	chroma_mat.set_shader_parameter("smoothness", 0.1)
	chroma_mat.set_shader_parameter("radius", 256.0)
	chroma_mat.set_shader_parameter("edge_smooth", 4.0)
	_overlay_badge.material = chroma_mat

	_overlay.add_child(_overlay_badge)
	_overlay_canvas.add_child(_overlay)
	add_child(_overlay_canvas)

	_kill_overlay_tween()
	_overlay_tween = create_tween()
	_overlay_tween.tween_property(black_bg, "color:a", 0.6, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_overlay_tween.parallel().tween_property(_overlay_badge, "position", center - video_size * 0.5, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_overlay_tween.parallel().tween_property(_overlay_badge, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_static_overlay() -> void:
	var vp_size = get_viewport().get_visible_rect().size
	var center = vp_size * 0.5
	var origin_center = get_global_center()

	_overlay_canvas = CanvasLayer.new()
	_overlay_canvas.layer = 100

	_overlay = Control.new()
	_overlay.name = "BadgeOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.gui_input.connect(_on_overlay_input)

	var black_bg = ColorRect.new()
	black_bg.name = "BlackBg"
	black_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_bg.color = Color(0, 0, 0, 0.0)
	black_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(black_bg)

	_overlay_badge = TextureRect.new()
	_overlay_badge.name = "OverlayBadge"
	_overlay_badge.texture = _badge_tex
	_overlay_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_overlay_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay_badge.size = OVERLAY_BADGE_SIZE
	_overlay_badge.position = origin_center - OVERLAY_BADGE_SIZE * 0.5
	_overlay_badge.pivot_offset = OVERLAY_BADGE_SIZE * 0.5
	_overlay_badge.scale = Vector2(size.x / OVERLAY_BADGE_SIZE.x, size.y / OVERLAY_BADGE_SIZE.y)
	_overlay_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_overlay_badge)

	_overlay_canvas.add_child(_overlay)
	add_child(_overlay_canvas)

	_kill_overlay_tween()
	_overlay_tween = create_tween()
	_overlay_tween.tween_property(black_bg, "color:a", 0.6, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_overlay_tween.parallel().tween_property(_overlay_badge, "position", center - OVERLAY_BADGE_SIZE * 0.5, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_overlay_tween.parallel().tween_property(_overlay_badge, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_badge_overlay() -> void:
	if not _is_showing_overlay:
		return
	if not is_instance_valid(_overlay):
		_cleanup_overlay()
		return

	var black_bg = _overlay.get_node_or_null("BlackBg")

	_kill_overlay_tween()
	_overlay_tween = create_tween()
	if black_bg:
		_overlay_tween.tween_property(black_bg, "color:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if is_instance_valid(_overlay_badge):
		var origin_center = get_global_center()
		var badge_size = _overlay_badge.size
		var target_scale = Vector2(size.x / badge_size.x, size.y / badge_size.y)
		_overlay_tween.parallel().tween_property(_overlay_badge, "position", origin_center - badge_size * 0.5, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_overlay_tween.parallel().tween_property(_overlay_badge, "scale", target_scale, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_overlay_tween.tween_callback(_cleanup_overlay)


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hide_badge_overlay()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_hide_badge_overlay()
		accept_event()


func _cleanup_overlay() -> void:
	_is_showing_overlay = false
	if is_instance_valid(_video_player):
		_video_player.stop()
	_video_player = null
	if is_instance_valid(_sub_viewport):
		_sub_viewport.queue_free()
	_sub_viewport = null
	if is_instance_valid(_overlay_canvas):
		_overlay_canvas.queue_free()
	_overlay_canvas = null
	_overlay = null
	_overlay_badge = null


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


func _kill_overlay_tween() -> void:
	if _overlay_tween and _overlay_tween.is_valid():
		_overlay_tween.kill()
	_overlay_tween = null


func get_global_center() -> Vector2:
	return global_position + size * 0.5
