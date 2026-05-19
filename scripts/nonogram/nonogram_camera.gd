extends Camera2D

signal zoom_changed(new_zoom: float)

var min_zoom: float = 1
var max_zoom: float = 1
var zoom_step: float = 0.1

var drag_sensitivity: float = 1.0
var drag_threshold: float = 10.0
var smooth_speed: float = 10.0
var _snap_threshold: float = 0.5

var minPosition:Vector2 = Vector2.ZERO
var maxPosition:Vector2 = Vector2(1280,720)

var is_dragging := false
var drag_start_position: Vector2 = position
var target_position: Vector2 = position
var viewport_size: Vector2 = Vector2.ZERO

var _touch_mode: bool = false

func _ready():
	viewport_size = get_viewport_rect().size
	maxPosition = viewport_size
	target_position = position

func reset_for_viewport() -> void:
	viewport_size = get_viewport_rect().size
	maxPosition = viewport_size
	target_position = viewport_size / 2
	position = target_position
	_update_bounds()

func set_touch_mode(enabled: bool) -> void:
	_touch_mode = enabled

func _unhandled_input(event: InputEvent) -> void:
	if not AnimationManager.wait_for_all_animations():
		return
	if _touch_mode:
		return
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
			zoom_changed.emit(zoom.x)
			if event.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SPACE):
				is_dragging = true
				drag_start_position = event.position
				get_viewport().set_input_as_handled()
		else:
			is_dragging = false
	if event is InputEventMouseMotion and is_dragging:
		if Input.is_key_pressed(KEY_SPACE):
			if (event.position - drag_start_position).length() > drag_threshold:
				var drag_offset = (drag_start_position - event.position) * drag_sensitivity / zoom.x
				target_position += drag_offset
				target_position = target_position.clamp(minPosition, maxPosition)
				drag_start_position = event.position
			get_viewport().set_input_as_handled()

func _update_bounds() -> void:
	minPosition = viewport_size / zoom / 2
	maxPosition = viewport_size - minPosition

func _process(delta):
	if position.distance_to(target_position) < _snap_threshold:
		position = target_position
	else:
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
