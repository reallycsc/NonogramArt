extends Control

const BookshelfDataScript = preload("res://scripts/data/bookshelf_data.gd")
const AlbumDataScript = preload("res://scripts/data/album_data.gd")
var book_button_scene: PackedScene = preload("res://scenes/book_button.tscn")

@onready var portrait_ui: Control = $PortraitUI
@onready var landscape_ui: Control = $LandscapeUI
@onready var p_title: Label = $PortraitUI/Title
@onready var p_vbox: VBoxContainer = $PortraitUI/VBoxContainer
@onready var l_title: Label = $LandscapeUI/Title
@onready var l_vbox: VBoxContainer = $LandscapeUI/VBoxContainer

@onready var canvas: CanvasLayer = $CanvasLayer
@onready var p_items: Control = $PortraitUI/Items
@onready var l_items: Control = $LandscapeUI/Items
@onready var settings_popup: Control = $CanvasLayer/SettingsPopup
@onready var left_button: TextureButton = $CanvasLayer/LeftButton
@onready var right_button: TextureButton = $CanvasLayer/RightButton
@onready var exit_popup: Control = $CanvasLayer/ExitConfirmPopup

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
	DLCManager.album_pack_loaded.connect(_on_album_pack_loaded)
	DLCManager.album_pack_download_failed.connect(_on_album_pack_download_failed)
	DLCManager.album_pack_download_progress.connect(_on_album_pack_download_progress)
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

var _display_cancelled: bool = false

func _display_albums() -> void:
	_display_cancelled = true
	await get_tree().process_frame
	_display_cancelled = false
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
	if _destroying or not is_inside_tree() or _display_cancelled:
		return

	var album_index: int = 0
	var animation_buttons: Array = []
	var row_counter: int = 0
	for album in current_albums:
		if _display_cancelled:
			return
		var row = _get_row_for_index(album_index)
		if row == null:
			break
		var book_btn = book_button_scene.instantiate()
		row.add_child(book_btn)
		book_btn.setup(album)
		book_btn.locked_album_clicked.connect(_on_locked_album_clicked)
		book_btn.download_album_clicked.connect(_on_download_album_clicked)
		if book_btn._needs_completion_animation:
			animation_buttons.append(book_btn)
		album_index += 1
		row_counter += 1
		if row_counter >= _books_per_row:
			row_counter = 0
			if _display_cancelled:
				return
			await get_tree().process_frame

	if _display_cancelled:
		return
	_play_completion_animations(animation_buttons)
	_update_items_visibility()

func _update_items_visibility() -> void:
	if _row_containers.size() < 5:
		return
	var items_parent = p_items if portrait_ui.visible else l_items
	for i in range(4):
		var row_index = i + 1
		var item = items_parent.get_node_or_null("Item" + str(i + 1))
		if item:
			item.visible = _row_containers[row_index].get_child_count() == 0

func _on_locked_album_clicked(album_id: String) -> void:
	AudioManager.play_sfx("click")
	_show_toast("完成前一本画册即可解锁")

func _play_completion_animations(buttons: Array) -> void:
	if buttons.is_empty():
		return
	AudioManager.play_sfx("congratulations")
	var stagger_delay: float = 0.35
	for i in range(buttons.size()):
		buttons[i].play_completion_animation(i * stagger_delay)

func _on_download_album_clicked(album_id: String) -> void:
	AudioManager.play_sfx("click")
	if DLCManager.is_downloading():
		_show_toast("正在下载中，请稍候...")
		return
	var btn = _find_book_button(album_id)
	if btn:
		btn.show_download_started()
	DLCManager.download_album(album_id)

func _on_album_pack_loaded(album_id: String) -> void:
	if is_inside_tree():
		_load_shelf()

func _on_album_pack_download_failed(album_id: String, error: String) -> void:
	_show_toast("下载失败: " + error)
	var btn = _find_book_button(album_id)
	if btn:
		btn.show_download_failed()

func _on_album_pack_download_progress(album_id: String, downloaded: int, total: int) -> void:
	var btn = _find_book_button(album_id)
	if btn:
		btn.update_download_progress(downloaded, total)

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
	if is_inside_tree() and not _destroying:
		await get_tree().process_frame

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	settings_popup.show_settings()

func _input(event: InputEvent) -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	if settings_popup.visible:
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
	ToastManager.show_toast(message)

func _find_book_button(target_album_id: String) -> Node:
	for row in _row_containers:
		for child in row.get_children():
			if child is TextureButton and child.album_id == target_album_id:
				return child
	return null

func _on_orientation_changed(new_orientation: int) -> void:
	_apply_orientation(new_orientation)

func _apply_orientation(orientation: int) -> void:
	if _destroying or not is_inside_tree():
		return
	if orientation == OrientationManager.Orientation.PORTRAIT:
		portrait_ui.visible = true
		landscape_ui.visible = false
		_books_per_row = BOOKS_PER_ROW_PORTRAIT
		_hide_all_items(l_items)
	else:
		portrait_ui.visible = false
		landscape_ui.visible = true
		_books_per_row = BOOKS_PER_ROW_LANDSCAPE
		_hide_all_items(p_items)
	_collect_row_containers()
	if not current_albums.is_empty():
		_display_albums()

func _hide_all_items(items_parent: Control) -> void:
	for i in range(4):
		var item = items_parent.get_node_or_null("Item" + str(i + 1))
		if item:
			item.visible = false

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
	left_button.visible = show_nav
	right_button.visible = show_nav
