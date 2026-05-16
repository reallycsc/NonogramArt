extends Control

const BookshelfDataScript = preload("res://scripts/data/bookshelf_data.gd")
const AlbumDataScript = preload("res://scripts/data/album_data.gd")
var book_button_scene: PackedScene = preload("res://scenes/book_button.tscn")

@onready var portrait_ui: Control = $PortraitUI
@onready var landscape_ui: Control = $LandscapeUI
@onready var portrait_canvas: CanvasLayer = $PortraitUI/CanvasLayer
@onready var landscape_canvas: CanvasLayer = $LandscapeUI/CanvasLayer

@onready var p_title: Label = $PortraitUI/Title
@onready var p_vbox: VBoxContainer = $PortraitUI/VBoxContainer
@onready var p_settings_popup: Control = $PortraitUI/CanvasLayer/SettingsPopup
@onready var p_left_button: TextureButton = $PortraitUI/CanvasLayer/LeftButton
@onready var p_right_button: TextureButton = $PortraitUI/CanvasLayer/RightButton

@onready var l_title: Label = $LandscapeUI/Title
@onready var l_vbox: VBoxContainer = $LandscapeUI/VBoxContainer
@onready var l_settings_popup: Control = $LandscapeUI/CanvasLayer/SettingsPopup
@onready var l_left_button: TextureButton = $LandscapeUI/CanvasLayer/LeftButton
@onready var l_right_button: TextureButton = $LandscapeUI/CanvasLayer/RightButton

var bookshelf_list: Array = []
var current_bookshelf_index: int = 0
var current_bookshelf_id: String = ""
var current_albums: Array = []
var current_album_id: String = ""
var _row_containers: Array = []
const BOOKS_PER_ROW_PORTRAIT: int = 3
const BOOKS_PER_ROW_LANDSCAPE: int = 4
var _books_per_row: int = BOOKS_PER_ROW_PORTRAIT

var _destroying: bool = false

var _swipe_start_pos: Vector2 = Vector2.ZERO
var _swipe_min_distance: float = 50.0

func _ready() -> void:
	bookshelf_list = _filter_valid_bookshelves(BookshelfDataScript.get_bookshelf_list())
	if GameManager.pending_bookshelf_id != "":
		for i in range(bookshelf_list.size()):
			if bookshelf_list[i]["id"] == GameManager.pending_bookshelf_id:
				current_bookshelf_index = i
				break
		GameManager.pending_bookshelf_id = ""
	OrientationManager.orientation_changed.connect(_on_orientation_changed)
	_apply_orientation(OrientationManager.current_orientation)
	GameManager.preload_scene("res://scenes/album_detail.tscn")
	_load_shelf()
	if GameManager.pending_album_id != "":
		AudioManager.play_bgm_for_album(GameManager.pending_album_id)
		GameManager.pending_album_id = ""
	else:
		AudioManager.play_bgm("main_menu")

func _exit_tree() -> void:
	_destroying = true
	if OrientationManager.orientation_changed.is_connected(_on_orientation_changed):
		OrientationManager.orientation_changed.disconnect(_on_orientation_changed)

func _get_active_vbox() -> VBoxContainer:
	if portrait_ui.visible:
		return p_vbox
	return l_vbox

func _collect_row_containers() -> void:
	_row_containers.clear()
	var vbox = _get_active_vbox()
	for child in vbox.get_children():
		if child is HBoxContainer:
			_row_containers.append(child)

func _load_shelf() -> void:
	if bookshelf_list.is_empty():
		bookshelf_list = _filter_valid_bookshelves(BookshelfDataScript.get_bookshelf_list())
	if bookshelf_list.is_empty():
		return
	current_bookshelf_index = clamp(current_bookshelf_index, 0, bookshelf_list.size() - 1)
	current_bookshelf_id = bookshelf_list[current_bookshelf_index]["id"]
	var bookshelf_data = BookshelfDataScript.get_bookshelf(current_bookshelf_id)
	p_title.text = bookshelf_data["name"]
	l_title.text = bookshelf_data["name"]
	current_albums = AlbumDataScript.load_albums(current_bookshelf_id)
	_update_nav_buttons()
	_display_albums()

func _display_albums() -> void:
	if _destroying or not is_inside_tree():
		return
	var has_children = false
	for row in _row_containers:
		if row.get_child_count() > 0:
			has_children = true
			for child in row.get_children():
				child.queue_free()
	if has_children:
		await _wait_for_free()
	if _destroying or not is_inside_tree():
		return

	var album_index: int = 0
	for album in current_albums:
		var row = _get_row_for_index(album_index)
		if row == null:
			break
		var book_btn = book_button_scene.instantiate()
		row.add_child(book_btn)
		book_btn.setup(album)
		book_btn.locked_album_clicked.connect(_on_locked_album_clicked)
		album_index += 1

func _on_locked_album_clicked(album_id: String) -> void:
	AudioManager.play_sfx("click")
	_show_toast("完成前一本画册即可解锁")

func _on_left_button_pressed() -> void:
	AudioManager.play_sfx("click")
	if bookshelf_list.size() > 0:
		current_bookshelf_index = (current_bookshelf_index - 1 + bookshelf_list.size()) % bookshelf_list.size()
		_load_shelf()

func _on_right_button_pressed() -> void:
	AudioManager.play_sfx("click")
	if bookshelf_list.size() > 0:
		current_bookshelf_index = (current_bookshelf_index + 1) % bookshelf_list.size()
		_load_shelf()

func _get_row_for_index(index: int) -> HBoxContainer:
	var row_index = index / _books_per_row
	if row_index < _row_containers.size():
		return _row_containers[row_index]
	return null

func _wait_for_free() -> void:
	var has_children = true
	while has_children:
		has_children = false
		for row in _row_containers:
			if row.get_child_count() > 0:
				has_children = true
				break
		if has_children:
			if not is_inside_tree() or _destroying:
				return
			await get_tree().process_frame

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	if portrait_ui.visible:
		p_settings_popup.show_settings()
	else:
		l_settings_popup.show_settings()

func _input(event: InputEvent) -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start_pos = event.position
		elif _swipe_start_pos != Vector2.ZERO:
			var delta = event.position - _swipe_start_pos
			if abs(delta.x) > _swipe_min_distance and abs(delta.x) > abs(delta.y):
				if delta.x > 0:
					_on_swipe_right()
				else:
					_on_swipe_left()
			_swipe_start_pos = Vector2.ZERO

func _on_swipe_left() -> void:
	if bookshelf_list.size() > 0:
		current_bookshelf_index = (current_bookshelf_index + 1) % bookshelf_list.size()
		_load_shelf()

func _on_swipe_right() -> void:
	if bookshelf_list.size() > 0:
		current_bookshelf_index = (current_bookshelf_index - 1 + bookshelf_list.size()) % bookshelf_list.size()
		_load_shelf()

func _show_toast(message: String) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 16.0
	style.content_margin_top = 8.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.modulate.a = 0.0
	add_child(panel)
	panel.offset_left = -panel.size.x / 2
	panel.offset_top = -panel.size.y / 2
	panel.offset_right = panel.size.x / 2
	panel.offset_bottom = panel.size.y / 2
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.label_settings = LabelSettings.new()
	label.label_settings.font_color = Color.WHITE
	label.label_settings.font_size = 24
	label.label_settings.outline_color = Color.BLACK
	label.label_settings.outline_size = 2
	panel.add_child(label)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "position:y", panel.position.y - 60, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.chain().tween_interval(1.0)
	tween.chain().tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(panel.queue_free)

func _on_orientation_changed(new_orientation: int) -> void:
	_apply_orientation(new_orientation)

func _apply_orientation(orientation: int) -> void:
	if _destroying or not is_inside_tree():
		return
	if orientation == OrientationManager.Orientation.PORTRAIT:
		portrait_ui.visible = true
		portrait_canvas.visible = true
		landscape_ui.visible = false
		landscape_canvas.visible = false
		_books_per_row = BOOKS_PER_ROW_PORTRAIT
	else:
		portrait_ui.visible = false
		portrait_canvas.visible = false
		landscape_ui.visible = true
		landscape_canvas.visible = true
		_books_per_row = BOOKS_PER_ROW_LANDSCAPE
	_collect_row_containers()
	if not current_albums.is_empty():
		_display_albums()

func _filter_valid_bookshelves(shelves: Array) -> Array:
	var result: Array = []
	for shelf in shelves:
		if not shelf is Dictionary or not shelf.has("id"):
			continue
		var shelf_id: String = shelf["id"]
		var albums = AlbumDataScript.load_albums(shelf_id)
		if not albums.is_empty():
			result.append(shelf)
	return result

func _update_nav_buttons() -> void:
	var show_nav = bookshelf_list.size() > 1
	p_left_button.visible = show_nav
	p_right_button.visible = show_nav
	l_left_button.visible = show_nav
	l_right_button.visible = show_nav
