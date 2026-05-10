extends Control

const BookshelfDataScript = preload("res://scripts/data/bookshelf_data.gd")
const AlbumDataScript = preload("res://scripts/data/album_data.gd")
var book_button_scene: PackedScene = preload("res://scenes/book_button.tscn")

@onready var bookshelf_container: VBoxContainer = $VBoxContainer
@onready var h_container: HBoxContainer = $VBoxContainer/HBoxContainer
@onready var settings_popup: Control = $CanvasLayer/SettingsPopup

var bookshelf_list: Array = []
var current_bookshelf_index: int = 0
var current_bookshelf_id: String = ""
var current_albums: Array = []
var _row_containers: Array = []
const BOOKS_PER_ROW: int = 3

func _ready() -> void:
	_collect_row_containers()
	bookshelf_list = BookshelfDataScript.get_bookshelf_list()
	if GameManager.pending_bookshelf_id != "":
		for i in range(bookshelf_list.size()):
			if bookshelf_list[i]["id"] == GameManager.pending_bookshelf_id:
				current_bookshelf_index = i
				break
		GameManager.pending_bookshelf_id = ""
	_load_shelf()
	AudioManager.play_bgm("main_menu")

func _collect_row_containers() -> void:
	_row_containers.clear()
	for child in bookshelf_container.get_children():
		if child is HBoxContainer:
			_row_containers.append(child)

func _load_shelf() -> void:
	if bookshelf_list.is_empty():
		bookshelf_list = BookshelfDataScript.get_bookshelf_list()
	if bookshelf_list.is_empty():
		return
	current_bookshelf_index = clamp(current_bookshelf_index, 0, bookshelf_list.size() - 1)
	current_bookshelf_id = bookshelf_list[current_bookshelf_index]["id"]
	var bookshelf_data = BookshelfDataScript.get_bookshelf(current_bookshelf_id)
	$Title.text = bookshelf_data["name"]
	current_albums = AlbumDataScript.load_albums(current_bookshelf_id)
	_display_albums()

func _display_albums() -> void:
	var has_children = false
	for row in _row_containers:
		if row.get_child_count() > 0:
			has_children = true
			for child in row.get_children():
				child.queue_free()
	if has_children:
		await _wait_for_free()

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
	var row_index = index / BOOKS_PER_ROW
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
			if not is_inside_tree():
				return
			await get_tree().process_frame

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	settings_popup.show_settings()

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
