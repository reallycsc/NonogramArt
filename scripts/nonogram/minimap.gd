extends Control

var camera: Camera2D
var game_board: Control
var board_size: Vector2
var cell_start_position: Vector2
var _original_board_size: Vector2
var grid_size: Vector2i

var _is_dragging: bool = false
var _target_alpha: float = 0.0
var _current_alpha: float = 0.0
var _fade_speed: float = 4.0
var _padding: float = 4.0
var _border_width: float = 2.0
var _max_dimension: float = 150.0
var _margin: float = 16.0
var _force_hide: bool = false

func _ready():
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50

func setup(cam: Camera2D, board: Control, b_size: Vector2, cell_start: Vector2, g_size: Vector2i, orig_b_size: Vector2):
	camera = cam
	game_board = board
	board_size = b_size
	cell_start_position = cell_start
	grid_size = g_size
	_original_board_size = orig_b_size
	_update_layout()

func _update_layout():
	if _original_board_size.x <= 0 or _original_board_size.y <= 0:
		return
	var aspect = _original_board_size.x / _original_board_size.y
	var w: float
	var h: float
	if aspect >= 1.0:
		w = _max_dimension
		h = _max_dimension / aspect
	else:
		h = _max_dimension
		w = _max_dimension * aspect
	size = Vector2(w + _padding * 2, h + _padding * 2)
	_update_position()

func _update_position():
	var viewport_size = get_viewport_rect().size
	position = Vector2(viewport_size.x - size.x - _margin, _margin)

func _process(delta):
	if _force_hide:
		return
	if camera == null:
		return
	_target_alpha = 1.0 if camera.zoom.x > 1.0 else 0.0
	if absf(_current_alpha - _target_alpha) > 0.001:
		_current_alpha = move_toward(_current_alpha, _target_alpha, _fade_speed * delta)
	else:
		_current_alpha = _target_alpha
	modulate.a = _current_alpha
	visible = _current_alpha > 0.01
	mouse_filter = Control.MOUSE_FILTER_STOP if _current_alpha > 0.5 else Control.MOUSE_FILTER_IGNORE
	_update_position()
	queue_redraw()

func _draw():
	if camera == null or game_board == null:
		return

	var map_rect = _get_map_rect()

	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	draw_rect(map_rect, Color(0.96, 0.91, 0.82, 0.9))

	if _original_board_size.x > 0 and _original_board_size.y > 0 and grid_size.x > 0 and grid_size.y > 0:
		var content_offset_ratio = cell_start_position / _original_board_size
		var content_size_ratio = Vector2.ONE - content_offset_ratio

		var content_pos = map_rect.position + content_offset_ratio * map_rect.size
		var content_size = content_size_ratio * map_rect.size

		draw_rect(Rect2(content_pos, content_size), Color(1, 1, 1, 0.95))

		var cell_w = content_size.x / float(grid_size.y)
		var cell_h = content_size.y / float(grid_size.x)

		var grid_color = Color(0.63, 0.47, 0.29, 0.4)
		for x in range(1, grid_size.x):
			var y_pos = content_pos.y + x * cell_h
			draw_line(Vector2(content_pos.x, y_pos), Vector2(content_pos.x + content_size.x, y_pos), grid_color, 1.0)
		for y in range(1, grid_size.y):
			var x_pos = content_pos.x + y * cell_w
			draw_line(Vector2(x_pos, content_pos.y), Vector2(x_pos, content_pos.y + content_size.y), grid_color, 1.0)

		var block_color = Color(0.63, 0.47, 0.29, 0.8)
		var block_size = 5
		for x in range(1, floori(float(grid_size.x) / float(block_size))):
			var y_pos = content_pos.y + block_size * x * cell_h
			draw_line(Vector2(content_pos.x, y_pos), Vector2(content_pos.x + content_size.x, y_pos), block_color, 2.0)
		for y in range(1, floori(float(grid_size.y) / float(block_size))):
			var x_pos = content_pos.x + block_size * y * cell_w
			draw_line(Vector2(x_pos, content_pos.y), Vector2(x_pos, content_pos.y + content_size.y), block_color, 2.0)

		var frame_color = Color(0.63, 0.47, 0.29, 1.0)
		draw_rect(Rect2(content_pos, content_size), frame_color, false, 2.0)

		for x in range(grid_size.x):
			for y in range(grid_size.y):
				if NonogramManager.player_grid[x][y] == NonogramManager.CellState.FILLED:
					draw_rect(Rect2(content_pos + Vector2(y * cell_w, x * cell_h), Vector2(cell_w, cell_h)), Color(0.76, 0.23, 0.13, 0.9))

	_draw_viewport_rect(map_rect)

func _draw_viewport_rect(map_rect: Rect2):
	if board_size.x <= 0 or board_size.y <= 0:
		return
	var viewport_size = camera.get_viewport_rect().size
	var zoom = camera.zoom.x
	var cam_pos = camera.position

	var vis_left = cam_pos.x - viewport_size.x / (2.0 * zoom)
	var vis_top = cam_pos.y - viewport_size.y / (2.0 * zoom)
	var vis_width = viewport_size.x / zoom
	var vis_height = viewport_size.y / zoom

	var board_pos = game_board.position

	var view_map_x = (vis_left - board_pos.x) / board_size.x * map_rect.size.x + map_rect.position.x
	var view_map_y = (vis_top - board_pos.y) / board_size.y * map_rect.size.y + map_rect.position.y
	var view_map_w = vis_width / board_size.x * map_rect.size.x
	var view_map_h = vis_height / board_size.y * map_rect.size.y

	draw_rect(Rect2(view_map_x, view_map_y, view_map_w, view_map_h), Color.WHITE, false, _border_width)

func _get_map_rect() -> Rect2:
	return Rect2(_padding, _padding, size.x - _padding * 2, size.y - _padding * 2)

func _gui_input(event: InputEvent):
	if camera == null or _current_alpha < 0.5:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = true
			_move_camera_to(event.position)
			accept_event()
		elif not event.pressed:
			_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		_move_camera_to(event.position)
		accept_event()

func _input(event: InputEvent):
	if camera == null or _current_alpha < 0.5:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var g_rect = get_global_rect()
			if g_rect.has_point(event.position):
				_is_dragging = true
				_move_camera_to(event.position - g_rect.position)
				get_viewport().set_input_as_handled()
		else:
			if _is_dragging:
				_is_dragging = false
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if _is_dragging:
			_move_camera_to(event.position - get_global_rect().position)
			get_viewport().set_input_as_handled()

func _move_camera_to(local_pos: Vector2):
	var map_rect = _get_map_rect()
	var board_pos = game_board.position

	var rel_x = clampf((local_pos.x - map_rect.position.x) / map_rect.size.x, 0.0, 1.0)
	var rel_y = clampf((local_pos.y - map_rect.position.y) / map_rect.size.y, 0.0, 1.0)

	camera.target_position = Vector2(
		board_pos.x + rel_x * board_size.x,
		board_pos.y + rel_y * board_size.y
	)
	camera.target_position = camera.target_position.clamp(camera.minPosition, camera.maxPosition)

func is_dragging_minimap() -> bool:
	return _is_dragging

func update_board_size(b_size: Vector2):
	board_size = b_size

func force_hide():
	_force_hide = true
	visible = false
	modulate.a = 0.0
	_current_alpha = 0.0

func force_show():
	_force_hide = false
