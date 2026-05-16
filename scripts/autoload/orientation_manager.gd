extends Node

enum Orientation { PORTRAIT, LANDSCAPE }

signal orientation_changed(new_orientation: int)

var current_orientation: int = Orientation.PORTRAIT
var auto_rotate_enabled: bool = true

const PORTRAIT_SIZE := Vector2i(720, 1280)
const LANDSCAPE_SIZE := Vector2i(1280, 720)

var _sensor_available: bool = false
var _is_desktop: bool = false
var _debounce_timer: float = 0.0
var _debounce_duration: float = 0.5
var _pending_orientation: int = Orientation.PORTRAIT
var _last_screen_size: Vector2i = Vector2i.ZERO

func _ready() -> void:
	_is_desktop = not DisplayServer.is_touchscreen_available() and Input.get_accelerometer() == Vector3.ZERO
	_detect_initial_orientation()
	_apply_viewport_size()
	_try_enable_sensor()
	if auto_rotate_enabled:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)
	else:
		_sync_display_orientation()
	var window = get_window()
	if window:
		window.size_changed.connect(_on_window_size_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		if auto_rotate_enabled:
			_check_orientation_by_screen_size()

func _on_window_size_changed() -> void:
	if auto_rotate_enabled:
		_check_orientation_by_screen_size()

func _detect_initial_orientation() -> void:
	var size = _get_effective_size()
	_last_screen_size = size
	if size.x >= size.y:
		current_orientation = Orientation.LANDSCAPE
	else:
		current_orientation = Orientation.PORTRAIT

func _get_effective_size() -> Vector2i:
	var win_size = DisplayServer.window_get_size()
	if win_size.x > 0 and win_size.y > 0:
		return win_size
	var window = get_window()
	if window:
		return Vector2i(int(window.size.x), int(window.size.y))
	return _last_screen_size

func _apply_viewport_size() -> void:
	var viewport = get_viewport()
	if not viewport:
		return
	if current_orientation == Orientation.PORTRAIT:
		viewport.content_scale_size = PORTRAIT_SIZE
	else:
		viewport.content_scale_size = LANDSCAPE_SIZE

func _try_enable_sensor() -> void:
	var accel = Input.get_accelerometer()
	var gyro = Input.get_gyroscope()
	_sensor_available = (accel != Vector3.ZERO or gyro != Vector3.ZERO)
	if not _sensor_available:
		_sensor_available = DisplayServer.is_touchscreen_available()

func _process(delta: float) -> void:
	if not auto_rotate_enabled:
		return
	if _is_desktop:
		return
	_check_orientation_by_sensor(delta)
	_check_orientation_by_screen_size()

func _check_orientation_by_sensor(delta: float) -> void:
	if not _sensor_available:
		return
	var accel = Input.get_accelerometer()
	if accel == Vector3.ZERO:
		return
	var detected: int
	if abs(accel.x) >= abs(accel.y):
		detected = Orientation.LANDSCAPE
	else:
		detected = Orientation.PORTRAIT
	if detected != current_orientation:
		if detected == _pending_orientation:
			_debounce_timer += delta
			if _debounce_timer >= _debounce_duration:
				_apply_orientation(detected)
				_debounce_timer = 0.0
		else:
			_pending_orientation = detected
			_debounce_timer = 0.0
	else:
		_debounce_timer = 0.0

func _check_orientation_by_screen_size() -> void:
	var size = _get_effective_size()
	if size == _last_screen_size:
		return
	_last_screen_size = size
	var detected: int
	if size.x >= size.y:
		detected = Orientation.LANDSCAPE
	else:
		detected = Orientation.PORTRAIT
	if detected != current_orientation:
		_apply_orientation(detected)

func _apply_orientation(orientation: int) -> void:
	current_orientation = orientation
	_apply_viewport_size()
	_sync_display_orientation()
	orientation_changed.emit(orientation)

func _sync_display_orientation() -> void:
	match current_orientation:
		Orientation.PORTRAIT:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		Orientation.LANDSCAPE:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

func set_auto_rotate(enabled: bool) -> void:
	auto_rotate_enabled = enabled
	if enabled:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)
		_detect_initial_orientation()
		_apply_viewport_size()
		_check_orientation_by_screen_size()
	else:
		_sync_display_orientation()

func is_landscape() -> bool:
	return current_orientation == Orientation.LANDSCAPE

func is_portrait() -> bool:
	return current_orientation == Orientation.PORTRAIT
