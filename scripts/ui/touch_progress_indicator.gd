extends Control

var progress: float = 0.0

var _ring_color: Color = Color(1, 1, 1, 1)
var _bg_color: Color = Color(1, 1, 1, 0.25)
var _ring_width: float = 20.0
var _radius: float = 100.0

func _ready():
	var s = _radius * 2.0 + _ring_width * 2.0
	custom_minimum_size = Vector2(s, s)
	size = custom_minimum_size
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw():
	var center = size / 2.0
	draw_arc(center, _radius, 0.0, TAU, 64, _bg_color, _ring_width, true)
	if progress > 0.001:
		var start_angle = -PI / 2.0
		var end_angle = start_angle + progress * TAU
		draw_arc(center, _radius, start_angle, end_angle, 64, _ring_color, _ring_width, true)

func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	queue_redraw()

func show_at(screen_pos: Vector2) -> void:
	position = screen_pos - size / 2.0
	progress = 0.0
	visible = true
	queue_redraw()

func hide_indicator() -> void:
	visible = false
	progress = 0.0
