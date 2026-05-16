extends Control

# 节点引用
@onready var game_board: Control = $GameBoard
@onready var cell_container: Control = $GameBoard/CellContainer
@onready var finish_button: TextureButton = $CanvasLayer/FinishButton
@onready var background: TextureRect = $Background

@onready var hp_node: HBoxContainer = $CanvasLayer/HpNode

@onready var finish_node: Control = $CanvasLayer/FinishNode
@onready var finish_particles: CPUParticles2D = $CanvasLayer/FinishNode/FinishParticles
@onready var finish_rect: TextureRect = $CanvasLayer/FinishNode/FinishTextureRect
@onready var finish_audio_player: AudioStreamPlayer2D = $CanvasLayer/FinishNode/FinishAudioPlayer

@onready var tips_node: Control = $CanvasLayer/TipsNode
@onready var tips_node2: Control = $CanvasLayer/TipsNode2

@onready var camera: Camera2D = $NonogramCamera
@onready var click_audio_player: AudioStreamPlayer2D = $ClickAudioPlayer
@onready var click_cross_audio_player: AudioStreamPlayer2D = $ClickCrossAudioPlayer
@onready var game_over_popup: Control = $CanvasLayer/GameOverPopup
@onready var check_button: CheckButton = $CanvasLayer/CheckButton
@onready var fill_label: RichTextLabel = $CanvasLayer/CheckButton/FillLabel
@onready var cross_label: RichTextLabel = $CanvasLayer/CheckButton/CrossLabel

var _is_touch_device: bool = false
var _touch_dragging: bool = false
var _touch_start_cell: Vector2i = Vector2i(-1, -1)
var _touch_last_cell: Vector2i = Vector2i(-1, -1)
var _touch_is_row_dragging: bool = false
var _touch_is_col_dragging: bool = false
var _touch_cell_state_pair: Vector2i = Vector2i(-1, -1)
var _touch_just_handled: bool = false

var _first_orientation_applied: bool = false

# 预制场景
var cell_scene: PackedScene = preload("res://scenes/cell_color.tscn")
var rowHint_scene: PackedScene = preload("res://scenes/row_hint.tscn")
var colHint_scene: PackedScene = preload("res://scenes/col_hint.tscn")

var cell_size:Vector2 = Vector2(32,32)
var cell_start_position = Vector2(0,0) # 格子在cellContainer中的起始位置
var board_size:Vector2 = Vector2.ZERO
var _original_board_size: Vector2 = Vector2.ZERO

var cells: Array[CellColor] = []
var rowHints: Array[RowHint] = []       # 行提示
var colHints: Array[ColHint] = []       # 行提示
var frames: Node2D

var is_dragging : bool = false
var last_cell_index: Vector2i = Vector2i(-1, -1)
var start_cell_index: Vector2i = Vector2i(-1, -1)
var is_row_dragging:bool = false
var is_col_dragging:bool = false
var button_index:int = MOUSE_BUTTON_LEFT
var cell_state_pair:Vector2i = Vector2i(-1, -1)
var grid_size:Vector2i = Vector2i.ZERO
var is_locked:bool = false
var is_replay: bool = false

var _album_id: String = ""
var _picture_id: String = ""
var _picture_index: int = -1

func _ready():
	# 连接信号
	GameManager.nonogram_cell_updated.connect(_on_cell_updated)
	GameManager.nonogram_cell_finished.connect(_on_cell_finished)
	GameManager.nonogram_rowHint_is_only_one_pattern.connect(_on_rowHint_is_only_one_pattern)
	GameManager.nonogram_rowHint_deducible.connect(_on_rowHint_deducible)
	GameManager.nonogram_rowHint_finished.connect(_on_rowHint_finished)
	GameManager.nonogram_rowHint_error.connect(_on_rowHint_error)
	GameManager.nonogram_colHint_is_only_one_pattern.connect(_on_colHint_is_only_one_pattern)
	GameManager.nonogram_colHint_deducible.connect(_on_colHint_deducible)
	GameManager.nonogram_colHint_finished.connect(_on_colHint_finished)
	GameManager.nonogram_colHint_error.connect(_on_colHint_error)
	GameManager.nonogram_game_completed.connect(_on_game_completed)
	GameManager.nonogram_life_updated.connect(_on_life_updated)
	GameManager.nonogram_game_over.connect(_on_game_over)
	GameManager.language_changed.connect(_on_language_changed)
	
	game_over_popup.restart_requested.connect(_on_restart_button_pressed)
	game_over_popup.exit_requested.connect(_on_back_button_pressed)

	OrientationManager.orientation_changed.connect(_on_orientation_changed)
	_apply_orientation(OrientationManager.current_orientation)
	
	_detect_input_device()
	check_button.button_pressed = true
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	if not NonogramManager.setup_game():
		printerr("数织关卡初始化失败")
		return
	grid_size = NonogramManager.grid_size
	# 清空现有格子
	for child in cell_container.get_children():
		child.queue_free()
	_album_id = GameManager.pending_album_id
	_picture_id = GameManager.pending_picture_id
	_picture_index = GameManager.pending_picture_index
	GameManager.pending_album_id = ""
	GameManager.pending_picture_id = ""
	GameManager.pending_picture_index = -1
	
	setup_hints()
	setup_grid()
	setup_frame_and_dividers()
	setup_board_size_and_position()
	setup_tips()
	setup_camera()
	NonogramManager.check_and_update_after_ready()
	AudioManager.play_bgm_for_album(_album_id)

	
	
# 设置提示数字
func setup_hints():
	rowHints.clear()
	colHints.clear()
	# 设置行提示
	var max_width = 0
	for x in range(grid_size.x):
		var row_hint = rowHint_scene.instantiate()
		cell_container.add_child(row_hint)
		rowHints.append(row_hint)
		var width = row_hint.setup(NonogramManager.get_row_hints(x), x)
		max_width = max(max_width, width)
	for row in rowHints:
		row.update_width(max_width)
	# 设置列提示
	var max_height = 0
	for y in range(grid_size.y):
		var col_hint = colHint_scene.instantiate()
		cell_container.add_child(col_hint)
		colHints.append(col_hint)
		var height = col_hint.setup(NonogramManager.get_col_hints(y), y)
		max_height = max(max_height, height)
	for col in colHints:
		col.update_height(max_height)
	# 设置行列提示的位置
	cell_start_position = Vector2(max_width, max_height)
	for x in range(grid_size.x):
		rowHints[x].position = Vector2(0,cell_start_position.y+cell_size.y*x)
	for y in range(grid_size.y):
		colHints[y].position = Vector2(cell_start_position.x+cell_size.x*y,0)
		
# 设置游戏网格
func setup_grid():
	# 创建新格子
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell = cell_scene.instantiate()
			cell_container.add_child(cell)
			cells.append(cell)
			cell.setup(x, y, NonogramManager.get_color_by_index(x,y))
			cell.position = cell_start_position+Vector2(y, x)*cell_size
			cell.cell_hover_updated.connect(_on_cell_hover_updated)
	# 计算棋盘大小
	board_size = cell_start_position + cell_size*Vector2(grid_size.y,grid_size.x)
	
func setup_frame_and_dividers():
	frames = Node2D.new()
	cell_container.add_child(frames)
	
	var block_size = 5
	var frame_line_width = 4
	var divide_line_width = 2
	var line_color = Color("a1784b")
	# 外框线
	var frame_left = ColorRect.new()
	frame_left.color = line_color
	frame_left.size = Vector2(frame_line_width, grid_size.x * cell_size.x+frame_line_width*2-2)
	frame_left.position = cell_start_position - Vector2(frame_line_width-1,frame_line_width-1)
	frames.add_child(frame_left)
	var frame_right = ColorRect.new()
	frame_right.color = line_color
	frame_right.size = Vector2(frame_line_width, grid_size.x * cell_size.x+frame_line_width*2-2)
	frame_right.position = Vector2(board_size.x-1,cell_start_position.y-frame_line_width+1)
	frames.add_child(frame_right)
	var frame_top = ColorRect.new()
	frame_top.color = line_color
	frame_top.size = Vector2(grid_size.y * cell_size.y+frame_line_width*2-2, frame_line_width)
	frame_top.position = cell_start_position - Vector2(frame_line_width-1,frame_line_width-1)
	frames.add_child(frame_top)
	var frame_bottom = ColorRect.new()
	frame_bottom.color = line_color
	frame_bottom.size = Vector2(grid_size.y * cell_size.y+frame_line_width*2-2, frame_line_width)
	frame_bottom.position = Vector2(cell_start_position.x-frame_line_width+1,board_size.y-1)
	frames.add_child(frame_bottom)
	# 中间分割线
	for y in range(1, floor(grid_size.y/block_size)):
		var line = ColorRect.new()
		line.color = line_color
		line.size = Vector2(divide_line_width, grid_size.x * cell_size.x+divide_line_width)
		line.position = cell_start_position + Vector2(block_size * y * cell_size.x, 0)-Vector2(divide_line_width,divide_line_width)/2
		frames.add_child(line)
	for x in range(1, floor(grid_size.x/block_size)):
		var line = ColorRect.new()
		line.color = line_color
		line.size = Vector2(grid_size.y * cell_size.y+divide_line_width, divide_line_width)
		line.position = cell_start_position + Vector2(0, block_size * x * cell_size.x)-Vector2(divide_line_width,divide_line_width)/2
		frames.add_child(line)
			
# 缩放整体大小并设置棋盘居中
func setup_board_size_and_position():
	var screen_size = get_viewport_rect().size
	if _original_board_size == Vector2.ZERO:
		_original_board_size = board_size
	var scale_vector = screen_size / _original_board_size * 0.9
	var new_scale = Vector2.ONE * min(scale_vector.x, scale_vector.y)
	game_board.scale = new_scale
	board_size = _original_board_size * new_scale
	game_board.position = (screen_size - board_size) / 2
	game_board.position.clamp(Vector2.ZERO, screen_size)
	
# 设置相机
func setup_camera():
	camera.make_current()
	camera.reset_for_viewport()
	camera.min_zoom = 1
	camera.max_zoom = 1.5

func setup_tips():
	match GameManager.current_language:
		GameManager.Language.CHINESE:
			$CanvasLayer/TipsNode/Mask.size.x = 220
			$CanvasLayer/TipsNode2/Mask.size.x = 220
		_:
			$CanvasLayer/TipsNode/Mask.size.x = 260
			$CanvasLayer/TipsNode2/Mask.size.x = 300
	if _is_touch_device:
		$CanvasLayer/TipsNode2/Label1.hide()
		$CanvasLayer/TipsNode2/Label2.show()
	else:
		$CanvasLayer/TipsNode2/Label1.show()
		$CanvasLayer/TipsNode2/Label2.hide()

func show_ui():
	$CanvasLayer.show()
	
# 格子更新回调
func _on_cell_updated(x: int, y: int, state: int):
	var cell_index = x * grid_size.y + y
	if cell_index < cells.size():
		var cell = cells[cell_index]
		cell.update_appearance(state)

# 格子完成回调
func _on_cell_finished(x: int, y: int, is_error: bool = false):
	var cell_index = x * grid_size.y + y
	if cell_index < cells.size():
		var cell = cells[cell_index]
		cell.finish(is_error)
		if is_error:
			cell.update_appearance(NonogramManager.finish_cell_for_error(x, y))

# 行提示只有1种模式回调
func  _on_rowHint_is_only_one_pattern(index: int):
	if index < rowHints.size():
		rowHints[index].update_only_one_pattern()
		
# 行提示可推理回调
func _on_rowHint_deducible(index: int, is_deducible: bool):
	if index < rowHints.size():
		rowHints[index].update_deducible(is_deducible)
		
# 行提示完成回调
func _on_rowHint_finished(index: int):
	if index < rowHints.size():
		rowHints[index].finish()
		
# 行提示错误回调
func _on_rowHint_error(index: int, is_error: bool):
	if index < rowHints.size():
		rowHints[index].update_error(is_error)

# 列提示只有1种模式回调
func  _on_colHint_is_only_one_pattern(index: int):
	if index < colHints.size():
		colHints[index].update_only_one_pattern()
		
# 列提示可推理回调
func _on_colHint_deducible(index: int, is_deducible: bool):
	if index < colHints.size():
		colHints[index].update_deducible(is_deducible)
		
# 列提示完成回调
func _on_colHint_finished(index: int):
	if index < colHints.size():
		colHints[index].finish()

# 列提示错误回调
func _on_colHint_error(index: int, is_error: bool):
	if index < colHints.size():
		colHints[index].update_error(is_error)

# 游戏完成回调
func _on_game_completed():
	tips_node.hide()
	tips_node2.hide()
	check_button.hide()
	hp_node.hide()
	is_locked = true
	# 相机复位动画
	if camera.zoom != Vector2.ONE:
		var tween_camera = create_tween()
		AnimationManager.register_tween(tween_camera)
		tween_camera.tween_property(camera, "zoom", Vector2.ONE, 0.5)
	# 播放恭喜完成的文字动画
	finish_node.show()
	finish_rect.scale = Vector2(0.8,0.8)
	finish_particles.restart()
	AudioManager.play_sfx("congratulations")
	var tween = create_tween()
	tween.set_parallel(true)
	AnimationManager.register_tween(tween)
	tween.tween_property(finish_rect, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 同时提示栏淡出
	for x in range(grid_size.x):
		tween.tween_property(rowHints[x], "modulate:a", 0, 0.5)
	for y in range(grid_size.y):
		tween.tween_property(colHints[y], "modulate:a", 0, 0.5)
	tween.tween_property(frames, "modulate:a", 0, 0.5)
	tween.finished.connect(_play_finish_animation1)

func _play_finish_animation1():
	await get_tree().create_timer(1.0).timeout
	# 创建像素图网格显示
	_create_pixel_grid_display()
	finish_node.hide()
	
	var tween = create_tween()
	AnimationManager.register_tween(tween)
	# 棋盘移动到居中为止
	var position_new = cell_container.position - cell_start_position/2
	tween.parallel().tween_property(cell_container, "position", position_new, 0.5)
	tween.finished.connect(_play_finish_animation2)

func _find_album_and_picture_for_puzzle(puzzle_id: String) -> Dictionary:
	var album_id = GameManager.get_album_id_for_puzzle(puzzle_id)
	if album_id != "":
		var picture_id = GameManager.get_picture_id_for_puzzle(puzzle_id)
		if picture_id != "":
			return {"album_id": album_id, "picture_id": picture_id}
	return {}

func _get_original_dims_for_picture(picture_id: String) -> Vector2:
	var album_id = GameManager.get_album_id_for_picture(picture_id)
	if album_id != "":
		var pictures = AlbumData.load_pictures(album_id)
		for p in pictures:
			if p.get("id", "") == picture_id:
				var puzzle_ids = p.get("puzzles", [])
				var max_x = 0.0
				var max_y = 0.0
				for pid in puzzle_ids:
					var puzzle = PuzzleData.load_puzzle(pid)
					if puzzle:
						var sr = puzzle.source_rect
						if sr.has("x") and sr.has("w"):
							max_x = max(max_x, float(sr.x) + float(sr.w))
						if sr.has("y") and sr.has("h"):
							max_y = max(max_y, float(sr.y) + float(sr.h))
				return Vector2(max_x, max_y)
	return Vector2.ZERO

func _create_pixel_grid_display():
	var puzzle = NonogramManager.current_puzzle
	if not puzzle:
		print("Error: puzzle is null")
		return

	var picture_id = puzzle.picture_id
	var album_id = _album_id
	var picture: Dictionary = {}

	if album_id != "" and picture_id != "":
		picture = AlbumData.get_picture(album_id, picture_id)

	if picture.is_empty():
		var resolved = _find_album_and_picture_for_puzzle(puzzle.id)
		if not resolved.is_empty():
			album_id = resolved["album_id"]
			picture_id = resolved["picture_id"]
			picture = AlbumData.get_picture(album_id, picture_id)

	if picture.is_empty():
		print("Error: picture not found for puzzle: ", puzzle.id, " picture_id: ", picture_id, " album_id: ", album_id)
		return

	var img_path = picture.get("image", "")
	if img_path == "":
		print("Error: image path is empty")
		return

	var base_path = img_path.get_basename()
	var pixel_path = base_path + "_nonogram_pixel.jpg"

	if not ResourceLoader.exists(pixel_path):
		print("Error: pixel image not found: ", pixel_path)
		return

	var tex = load(pixel_path)
	if not tex is Texture2D:
		print("Error: loaded resource is not a Texture2D")
		return

	var source_rect = puzzle.source_rect
	var pixel_img = tex.get_image()

	if source_rect.has("x") and source_rect.has("y") and source_rect.has("w") and source_rect.has("h"):
		var orig_dims = _get_original_dims_for_picture(puzzle.picture_id)
		var scale_x = float(pixel_img.get_width()) / orig_dims.x if orig_dims.x > 0 else 1.0
		var scale_y = float(pixel_img.get_height()) / orig_dims.y if orig_dims.y > 0 else 1.0
		var rect = Rect2i(
			int(float(source_rect.x) * scale_x),
			int(float(source_rect.y) * scale_y),
			int(float(source_rect.w) * scale_x),
			int(float(source_rect.h) * scale_y)
		)
		pixel_img = pixel_img.get_region(rect)

	var pixel_tex = ImageTexture.create_from_image(pixel_img)

	var pixel_rect = TextureRect.new()
	pixel_rect.name = "PixelGridRect"
	pixel_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pixel_rect.stretch_mode = TextureRect.STRETCH_SCALE
	pixel_rect.texture = pixel_tex
	pixel_rect.custom_minimum_size = cell_size * Vector2(grid_size.y, grid_size.x)
	pixel_rect.size = pixel_rect.custom_minimum_size
	pixel_rect.position = cell_start_position

	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = preload("res://shaders/sweep_reveal.gdshader")
	shader_mat.set_shader_parameter("progress", 0.0)
	shader_mat.set_shader_parameter("sweep_width", 0.08)
	pixel_rect.material = shader_mat

	cell_container.add_child(pixel_rect)

func _play_finish_animation2():
	var pixel_rect = cell_container.get_node_or_null("PixelGridRect")
	if not pixel_rect:
		finish_button.show()
		return

	var shader_mat = pixel_rect.material as ShaderMaterial
	if not shader_mat:
		finish_button.show()
		return

	var sweep_duration = 1.5
	var max_diag = float(grid_size.x + grid_size.y - 2)
	if max_diag < 1.0:
		max_diag = 1.0

	var tween = create_tween()
	AnimationManager.register_tween(tween)
	tween.set_parallel(true)

	tween.tween_property(shader_mat, "shader_parameter/progress", 1.15, sweep_duration)

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var idx = x * grid_size.y + y
			if idx < cells.size():
				var delay = (float(x) + float(y)) / max_diag * sweep_duration * 0.85
				tween.tween_property(cells[idx], "modulate:a", 0.0, 0.25).set_delay(delay)

	tween.finished.connect(func():
		finish_button.show()
	)

# 格子悬浮回调
func _on_cell_hover_updated(x: int, y: int, is_hover: bool):
	if is_locked:
		return
	rowHints[x].update_hover(is_hover)
	colHints[y].update_hover(is_hover)
	for y1 in range(grid_size.y):
		cells[x * grid_size.y + y1].update_hover(is_hover)
	for x1 in range(grid_size.x):
		cells[x1 * grid_size.y + y].update_hover(is_hover)

func _on_back_button_pressed() -> void:
	AudioManager.play_sfx("click")
	GameManager.pending_album_id = _album_id
	GameManager.pending_picture_id = _picture_id
	GameManager.pending_picture_index = _picture_index
	get_tree().change_scene_to_file("res://scenes/album_detail.tscn")
	
func _on_restart_button_pressed() -> void:
	AudioManager.play_sfx("click")
	GameManager.pending_album_id = _album_id
	GameManager.pending_picture_id = _picture_id
	GameManager.pending_picture_index = _picture_index
	GameManager.pending_puzzle_id = NonogramManager.current_puzzle.id if NonogramManager.current_puzzle else ""
	get_tree().change_scene_to_file("res://scenes/nonogram_scene.tscn")
	
func _on_finish_button_pressed() -> void:
	AudioManager.play_sfx("click")
	GameManager.pending_album_id = _album_id
	GameManager.pending_picture_id = _picture_id
	GameManager.pending_picture_index = _picture_index
	get_tree().change_scene_to_file("res://scenes/album_detail.tscn")

func _on_finish_button_test_pressed() -> void:
	AudioManager.play_sfx("click")
	$CanvasLayer/FinishButtonTest.hide()
	_on_game_completed()

# 输入处理
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()
		return
	if is_locked:
		return
	if event is InputEventMouseMotion and is_dragging:
		# 只处理和初始格子相同行或相同列的格子
		var cell_index = get_cell_at_position(camera.get_global_mouse_position())
		if is_valid_cell_position(cell_index)  and not is_cell_finished(cell_index) and cell_index != last_cell_index:
			if not is_row_dragging and not is_col_dragging:
				if cell_index.x != start_cell_index.x:
					is_row_dragging = true
				elif cell_index.y != start_cell_index.y:
					is_col_dragging = true
			var is_error = false
			if is_row_dragging:
				if last_cell_index.x < cell_index.x:
					for i in range(last_cell_index.x, cell_index.x+1):
						NonogramManager.on_cell_dragging(i, start_cell_index.y, button_index, cell_state_pair)
						is_error = NonogramManager.check_and_handle_error(i, start_cell_index.y, cell_state_pair.y)
						if is_error:
							_on_cell_finished(i, start_cell_index.y, is_error)
							break
				elif last_cell_index.x > cell_index.x:
					for i in range(cell_index.x, last_cell_index.x):
						NonogramManager.on_cell_dragging(i, start_cell_index.y, button_index, cell_state_pair)
						is_error = NonogramManager.check_and_handle_error(i, start_cell_index.y, cell_state_pair.y)
						if is_error:
							_on_cell_finished(i, start_cell_index.y, is_error)
							break
			elif is_col_dragging:
				if last_cell_index.y < cell_index.y:
					for i in range(last_cell_index.y, cell_index.y+1):
						NonogramManager.on_cell_dragging(start_cell_index.x, i, button_index, cell_state_pair)
						is_error = NonogramManager.check_and_handle_error(start_cell_index.x, i, cell_state_pair.y)
						if is_error:
							_on_cell_finished(start_cell_index.x, i, is_error)
							break
				elif last_cell_index.y > cell_index.y:
					for i in range(cell_index.y, last_cell_index.y):
						NonogramManager.on_cell_dragging(start_cell_index.x, i, button_index, cell_state_pair)
						is_error = NonogramManager.check_and_handle_error(start_cell_index.x, i, cell_state_pair.y)
						if is_error:
							_on_cell_finished(start_cell_index.x, i, is_error)
							break
			last_cell_index = cell_index
			if is_error:
				is_dragging = false
			else:
				if button_index == MOUSE_BUTTON_LEFT:
					AudioManager.play_sfx("nonogram_click")
				elif button_index == MOUSE_BUTTON_RIGHT:
					AudioManager.play_sfx("nonogram_click_cross")
		get_viewport().set_input_as_handled()
	# 鼠标点击
	elif event is InputEventMouseButton:
		if _touch_just_handled:
			_touch_just_handled = false
			return
		if event.pressed:
			var cell_index = get_cell_at_position(camera.get_global_mouse_position())
			if is_valid_cell_position(cell_index) and not is_cell_finished(cell_index):
				cell_state_pair = NonogramManager.on_cell_clicked(cell_index.x, cell_index.y, event.button_index)
				# 检查错误填充
				var is_error = NonogramManager.check_and_handle_error(cell_index.x, cell_index.y, cell_state_pair.y)
				if is_error:
					_on_cell_finished(cell_index.x, cell_index.y, is_error)
				else: 
					is_dragging = true
					start_cell_index = cell_index
					last_cell_index = cell_index
					button_index = event.button_index
					if button_index == MOUSE_BUTTON_LEFT:
						AudioManager.play_sfx("nonogram_click")
					elif button_index == MOUSE_BUTTON_RIGHT:
						AudioManager.play_sfx("nonogram_click_cross")
		else:
			cell_state_pair = Vector2i(-1, -1)
			is_dragging = false
			is_row_dragging = false
			is_col_dragging = false
			start_cell_index = Vector2i(-1, -1)
			last_cell_index = Vector2i(-1, -1)
			button_index = MOUSE_BUTTON_NONE
		get_viewport().set_input_as_handled()

# 根据位置找到格子编号
func get_cell_at_position(canvas_pos: Vector2) -> Vector2i:
	var local_pos: Vector2 = canvas_pos-game_board.position-cell_start_position*game_board.scale
	var index = local_pos / (cell_size*game_board.scale)
	var cell_index = Vector2(index.y, index.x)
	cell_index.clamp(Vector2.ZERO, grid_size-Vector2i.ONE)
	return cell_index
	
# 检查格子坐标是否有效
func is_valid_cell_position(cell_index: Vector2i) -> bool:
	return (cell_index.x >= 0 and cell_index.y >= 0 and cell_index.x < grid_size.x and cell_index.y < grid_size.y)

# 检查格子是否已结束
func is_cell_finished(cell_index: Vector2i) -> bool:
	var index = cell_index.x * grid_size.y + cell_index.y
	if index < cells.size():
		var cell = cells[index]
		return cell.is_finished
	return false

# 生命值更新回调
func _on_life_updated(life: int, x: int = 0, y: int = 0):
	var cell_index = x * grid_size.y + y
	if cell_index < cells.size():
		var cell = cells[cell_index]
		cell.life_change()
	# 计算生命值变化
	var change = life - hp_node.current_hp
	hp_node.hp_change(change)
	AudioManager.play_sfx("life_change")
	# 触发相机震动效果
	camera.shake()

# 游戏结束回调
func _on_game_over():
	is_locked = true
	tips_node.hide()
	tips_node2.hide()
	check_button.hide()
	game_over_popup.show_game_over()

func _on_language_changed(language: int) -> void:
	setup_tips()
	
func _exit_tree() -> void:
	if OrientationManager.orientation_changed.is_connected(_on_orientation_changed):
		OrientationManager.orientation_changed.disconnect(_on_orientation_changed)
	GameManager.nonogram_cell_updated.disconnect(_on_cell_updated)
	GameManager.nonogram_cell_finished.disconnect(_on_cell_finished)
	GameManager.nonogram_rowHint_is_only_one_pattern.disconnect(_on_rowHint_is_only_one_pattern)
	GameManager.nonogram_rowHint_deducible.disconnect(_on_rowHint_deducible)
	GameManager.nonogram_rowHint_finished.disconnect(_on_rowHint_finished)
	GameManager.nonogram_rowHint_error.disconnect(_on_rowHint_error)
	GameManager.nonogram_colHint_is_only_one_pattern.disconnect(_on_colHint_is_only_one_pattern)
	GameManager.nonogram_colHint_deducible.disconnect(_on_colHint_deducible)
	GameManager.nonogram_colHint_finished.disconnect(_on_colHint_finished)
	GameManager.nonogram_colHint_error.disconnect(_on_colHint_error)
	GameManager.nonogram_game_completed.disconnect(_on_game_completed)
	GameManager.nonogram_life_updated.disconnect(_on_life_updated)
	GameManager.nonogram_game_over.disconnect(_on_game_over)
	GameManager.language_changed.disconnect(_on_language_changed)


func _detect_input_device() -> void:
	var has_mouse = Input.get_connected_joypads().size() == 0 and DisplayServer.is_touchscreen_available() == false
	var mouse_mode = Input.mouse_mode
	if mouse_mode == Input.MOUSE_MODE_HIDDEN or mouse_mode == Input.MOUSE_MODE_CONFINED_HIDDEN:
		has_mouse = false
	if DisplayServer.is_touchscreen_available():
		_is_touch_device = true
	else:
		_is_touch_device = false
	check_button.visible = _is_touch_device
	camera.set_touch_mode(_is_touch_device)

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_detect_input_device()

func _get_touch_button_index() -> int:
	if check_button.button_pressed:
		return MOUSE_BUTTON_LEFT
	else:
		return MOUSE_BUTTON_RIGHT

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var canvas_transform = get_viewport().canvas_transform
	return canvas_transform.affine_inverse() * screen_pos

func _handle_touch_input(event: InputEventScreenTouch) -> void:
	if is_locked:
		return
	if event.pressed:
		var cell_index = get_cell_at_position(_screen_to_world(event.position))
		if is_valid_cell_position(cell_index) and not is_cell_finished(cell_index):
			var btn_idx = _get_touch_button_index()
			_touch_cell_state_pair = NonogramManager.on_cell_clicked(cell_index.x, cell_index.y, btn_idx)
			var is_error = NonogramManager.check_and_handle_error(cell_index.x, cell_index.y, _touch_cell_state_pair.y)
			if is_error:
				_on_cell_finished(cell_index.x, cell_index.y, is_error)
			else:
				_touch_dragging = true
				_touch_start_cell = cell_index
				_touch_last_cell = cell_index
				_touch_is_row_dragging = false
				_touch_is_col_dragging = false
				if btn_idx == MOUSE_BUTTON_LEFT:
					AudioManager.play_sfx("nonogram_click")
				else:
					AudioManager.play_sfx("nonogram_click_cross")
	else:
		_touch_cell_state_pair = Vector2i(-1, -1)
		_touch_dragging = false
		_touch_is_row_dragging = false
		_touch_is_col_dragging = false
		_touch_start_cell = Vector2i(-1, -1)
		_touch_last_cell = Vector2i(-1, -1)

func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	if is_locked or not _touch_dragging:
		return
	var cell_index = get_cell_at_position(_screen_to_world(event.position))
	if is_valid_cell_position(cell_index) and not is_cell_finished(cell_index) and cell_index != _touch_last_cell:
		if not _touch_is_row_dragging and not _touch_is_col_dragging:
			if cell_index.x != _touch_start_cell.x:
				_touch_is_row_dragging = true
			elif cell_index.y != _touch_start_cell.y:
				_touch_is_col_dragging = true
		var btn_idx = _get_touch_button_index()
		var is_error = false
		if _touch_is_row_dragging:
			if _touch_last_cell.x < cell_index.x:
				for i in range(_touch_last_cell.x, cell_index.x + 1):
					NonogramManager.on_cell_dragging(i, _touch_start_cell.y, btn_idx, _touch_cell_state_pair)
					is_error = NonogramManager.check_and_handle_error(i, _touch_start_cell.y, _touch_cell_state_pair.y)
					if is_error:
						_on_cell_finished(i, _touch_start_cell.y, is_error)
						break
			elif _touch_last_cell.x > cell_index.x:
				for i in range(cell_index.x, _touch_last_cell.x):
					NonogramManager.on_cell_dragging(i, _touch_start_cell.y, btn_idx, _touch_cell_state_pair)
					is_error = NonogramManager.check_and_handle_error(i, _touch_start_cell.y, _touch_cell_state_pair.y)
					if is_error:
						_on_cell_finished(i, _touch_start_cell.y, is_error)
						break
		elif _touch_is_col_dragging:
			if _touch_last_cell.y < cell_index.y:
				for i in range(_touch_last_cell.y, cell_index.y + 1):
					NonogramManager.on_cell_dragging(_touch_start_cell.x, i, btn_idx, _touch_cell_state_pair)
					is_error = NonogramManager.check_and_handle_error(_touch_start_cell.x, i, _touch_cell_state_pair.y)
					if is_error:
						_on_cell_finished(_touch_start_cell.x, i, is_error)
						break
			elif _touch_last_cell.y > cell_index.y:
				for i in range(cell_index.y, _touch_last_cell.y):
					NonogramManager.on_cell_dragging(_touch_start_cell.x, i, btn_idx, _touch_cell_state_pair)
					is_error = NonogramManager.check_and_handle_error(_touch_start_cell.x, i, _touch_cell_state_pair.y)
					if is_error:
						_on_cell_finished(_touch_start_cell.x, i, is_error)
						break
		_touch_last_cell = cell_index
		if is_error:
			_touch_dragging = false
		else:
			if btn_idx == MOUSE_BUTTON_LEFT:
				AudioManager.play_sfx("nonogram_click")
			else:
				AudioManager.play_sfx("nonogram_click_cross")

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.index == 0:
		_touch_just_handled = true
		_handle_touch_input(event)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == 0:
		_handle_touch_drag(event)
		get_viewport().set_input_as_handled()

func _on_orientation_changed(new_orientation: int) -> void:
	_apply_orientation(new_orientation)

func _apply_orientation(orientation: int) -> void:
	if not is_inside_tree():
		return
	camera.reset_for_viewport()
	if _original_board_size != Vector2.ZERO:
		setup_board_size_and_position()
	if _first_orientation_applied:
		BackgroundManager.apply_background_with_transition(background, "nonogram", orientation, self)
	else:
		BackgroundManager.apply_background(background, "nonogram", orientation)
		_first_orientation_applied = true
