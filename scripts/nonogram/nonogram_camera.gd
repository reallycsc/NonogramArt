extends Camera2D

var min_zoom: float = 1
var max_zoom: float = 1
var zoom_step: float = 0.1

var drag_sensitivity: float = 1.0
var drag_threshold: float = 10.0
var smooth_speed: float = 10.0

var minPosition:Vector2 = Vector2.ZERO
var maxPosition:Vector2 = Vector2(1280,720)

var is_dragging := false
var drag_start_position: Vector2 = position
var target_position: Vector2 = position
var viewport_size: Vector2 = Vector2.ZERO

var _touch_mode: bool = false
var _pinch_touches: Dictionary = {}
var _pinch_start_distance: float = 0.0
var _pinch_start_zoom: Vector2 = Vector2.ONE
var _pinch_start_center: Vector2 = Vector2.ZERO
var _pinch_drag_start_pos: Vector2 = Vector2.ZERO

func _ready():
	viewport_size = get_viewport_rect().size
	maxPosition = viewport_size

func set_touch_mode(enabled: bool) -> void:
	_touch_mode = enabled

func _unhandled_input(event: InputEvent) -> void:
	if not AnimationManager.wait_for_all_animations():
		return
	if _touch_mode:
		_handle_touch_input(event)
	else:
		_handle_mouse_input(event)

func _handle_mouse_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom += Vector2(zoom_step, zoom_step)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom -= Vector2(zoom_step, zoom_step)
			zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
			_update_bounds()
			position = position.clamp(minPosition, maxPosition)
			target_position = target_position.clamp(minPosition, maxPosition)
			if event.button_index == MOUSE_BUTTON_LEFT and event.ctrl_pressed:
				is_dragging = true
				drag_start_position = event.position
				get_viewport().set_input_as_handled()
		else:
			is_dragging = false
	if event is InputEventMouseMotion and is_dragging:
		if event.ctrl_pressed:
			if (event.position - drag_start_position).length() > drag_threshold:
				var drag_offset = (drag_start_position - event.position) * drag_sensitivity / zoom.x
				target_position += drag_offset
				target_position = target_position.clamp(minPosition, maxPosition)
				drag_start_position = event.position
			get_viewport().set_input_as_handled()

func _handle_touch_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_pinch_touches[event.index] = event.position
			if _pinch_touches.size() == 2:
				var positions = _pinch_touches.values()
				_pinch_start_distance = positions[0].distance_to(positions[1])
				_pinch_start_zoom = zoom
				_pinch_start_center = (positions[0] + positions[1]) / 2.0
				_pinch_drag_start_pos = target_position
		else:
			_pinch_touches.erase(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_pinch_touches[event.index] = event.position
		if _pinch_touches.size() == 2:
			var positions = _pinch_touches.values()
			var current_distance = positions[0].distance_to(positions[1])
			if _pinch_start_distance > 0.0:
				var scale_factor = current_distance / _pinch_start_distance
				var new_zoom = _pinch_start_zoom * scale_factor
				new_zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
				zoom = new_zoom
				_update_bounds()
				var current_center = (positions[0] + positions[1]) / 2.0
				var center_delta = (_pinch_start_center - current_center) / zoom.x
				target_position = _pinch_drag_start_pos + center_delta
				target_position = target_position.clamp(minPosition, maxPosition)
			get_viewport().set_input_as_handled()

func _update_bounds() -> void:
	minPosition = viewport_size / zoom / 2
	maxPosition = viewport_size - minPosition

func _process(delta):
	position = position.lerp(target_position, smooth_speed * delta)

func reset():
	zoom = Vector2.ONE
	min_zoom = 1
	max_zoom = 1

func shake(intensity: float = 20.0):
	var original_position = position
	var shake_offset = Vector2(intensity, -intensity)
	target_position = original_position + shake_offset
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	target_position = original_position
