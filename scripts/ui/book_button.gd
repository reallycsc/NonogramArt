extends TextureButton

const BTN_NORMAL = preload("res://assets/images/ui/bookshelf/bookcover/book_blank.png")
const BTN_HOVER = preload("res://assets/images/ui/bookshelf/bookcover/book_blank_hover.png")
const BTN_PRESSED = preload("res://assets/images/ui/bookshelf/bookcover/book_blank_pressed.png")
const BTN_GREY_NORMAL = preload("res://assets/images/ui/bookshelf/bookcover/book_blank_grey.png")
const BTN_GREY_HOVER = preload("res://assets/images/ui/bookshelf/bookcover/book_blank_hover_grey.png")
const BTN_GREY_PRESSED = preload("res://assets/images/ui/bookshelf/bookcover/book_blank_pressed_grey.png")

signal locked_album_clicked(album_id: String)

@onready var book_icon: Sprite2D = $BookIconNode/BookIcon
@onready var lock_label: Label = $BookIconNode/LockLabel
@onready var status_label: Label = $BookIconNode/StatusLabel
@onready var book_name: Label = $BookName

var album_id: String = ""

func setup(data: Dictionary) -> void:
	album_id = data.get("id", "")
	book_name.text = data.get("name", "")

	var unlock_result = GameManager.get_album_unlock_status(album_id)
	if not unlock_result.unlocked:
		lock_label.show()
		texture_normal = BTN_GREY_NORMAL
		texture_hover = BTN_GREY_HOVER
		texture_pressed = BTN_GREY_PRESSED
		self_modulate = Color(0.4, 0.4, 0.4)
		book_icon.texture = GameManager.get_album_icon_grey(album_id)
		book_icon.modulate = Color(0.4, 0.4, 0.4)
		status_label.text = "未解锁"
		status_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		lock_label.hide()
		var completion = GameManager.get_album_completion(album_id)
		if completion >= 1.0 or GameManager.test_mode:
			book_icon.texture = GameManager.get_album_icon(album_id)
			if completion >= 1.0:
				status_label.text = "已完成"
				status_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2))
			else:
				status_label.text = "%d%%" % int(completion * 100)
				status_label.add_theme_color_override("font_color", Color.WHITE)
		else:
			texture_normal = BTN_GREY_NORMAL
			texture_hover = BTN_GREY_HOVER
			texture_pressed = BTN_GREY_PRESSED
			book_icon.texture = GameManager.get_album_icon_grey(album_id)
			status_label.text = "%d%%" % int(completion * 100)
			status_label.add_theme_color_override("font_color", Color.WHITE)

func _on_book_button_pressed() -> void:
	if album_id == "":
		return
	var unlock_result = GameManager.get_album_unlock_status(album_id)
	if not unlock_result.unlocked:
		locked_album_clicked.emit(album_id)
		return
	AudioManager.play_sfx("click")
	GameManager.pending_album_id = album_id
	get_tree().change_scene_to_file("res://scenes/album_detail.tscn")
