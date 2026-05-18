extends CanvasLayer

var _pool: Array[PanelContainer] = []
var _pool_size: int = 5
var _active: Array[PanelContainer] = []
var _style: StyleBoxFlat = null
var _label_settings: LabelSettings = null
var _vertical_spacing: float = 50.0

func _ready():
	layer = 10
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0, 0, 0, 0.6)
	_style.corner_radius_top_left = 8
	_style.corner_radius_top_right = 8
	_style.corner_radius_bottom_right = 8
	_style.corner_radius_bottom_left = 8
	_style.content_margin_left = 16.0
	_style.content_margin_top = 8.0
	_style.content_margin_right = 16.0
	_style.content_margin_bottom = 8.0
	_label_settings = LabelSettings.new()
	_label_settings.font_color = Color.WHITE
	_label_settings.font_size = 24
	_label_settings.outline_color = Color.BLACK
	_label_settings.outline_size = 2
	for i in _pool_size:
		_pool.append(_create_panel())

func _create_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.label_settings = _label_settings
	panel.add_child(label)
	add_child(panel)
	return panel

func _recalc_positions() -> void:
	var count = _active.size()
	for i in count:
		var p = _active[i]
		var offset_y = -float(count - 1) * _vertical_spacing / 2.0 + float(i) * _vertical_spacing
		p.offset_left = -p.size.x / 2
		p.offset_top = offset_y - p.size.y / 2
		p.offset_right = p.size.x / 2
		p.offset_bottom = offset_y + p.size.y / 2

func show_toast(message: String) -> void:
	var panel: PanelContainer
	if _pool.size() > 0:
		panel = _pool.pop_back()
	else:
		panel = _active.pop_front()
		if panel:
			var tw = panel.get_meta("_toast_tween", null) as Tween
			if tw and tw.is_valid():
				tw.kill()
			panel.visible = false
		else:
			panel = _create_panel()
	var label = panel.get_child(0) as Label
	label.text = message
	panel.modulate.a = 0.0
	panel.visible = true
	_active.append(panel)
	_recalc_positions()
	var base_offset_top = panel.offset_top
	var base_offset_bottom = panel.offset_bottom
	var tween = create_tween()
	panel.set_meta("_toast_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(panel, "offset_top", base_offset_top - 30, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "offset_bottom", base_offset_bottom - 30, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.chain().tween_interval(1.0)
	tween.chain().tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(func():
		panel.visible = false
		_active.erase(panel)
		_recalc_positions()
		if _pool.size() < _pool_size:
			_pool.append(panel)
	)
