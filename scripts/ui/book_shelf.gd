extends Control

const BookshelfDataScript = preload("res://scripts/data/bookshelf_data.gd")
const AlbumDataScript = preload("res://scripts/data/album_data.gd")
var book_button_scene: PackedScene = preload("res://scenes/book_button.tscn")

@onready var bookshelf_container: VBoxContainer = $VBoxContainer
@onready var h_container: HBoxContainer = $VBoxContainer/HBoxContainer

var bookshelf_list: Array = []
var current_bookshelf_id: String = ""
var current_albums: Array = []
var _row_containers: Array = []
const BOOKS_PER_ROW: int = 3

func _ready() -> void:
	_collect_row_containers()
	if GameManager.pending_bookshelf_id != "":
		current_bookshelf_id = GameManager.pending_bookshelf_id
		GameManager.pending_bookshelf_id = ""
	_load_shelf()

func _collect_row_containers() -> void:
	_row_containers.clear()
	for child in bookshelf_container.get_children():
		if child is HBoxContainer:
			_row_containers.append(child)

func _load_shelf() -> void:
	if current_bookshelf_id == "":
		bookshelf_list = BookshelfDataScript.get_bookshelf_list()
		if not bookshelf_list.is_empty():
			current_bookshelf_id = bookshelf_list[0]["id"]
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
		album_index += 1

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
			await get_tree().process_frame

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
