extends TextureButton

const BTN_NORMAL = preload("res://assets/images/ui/bookshelf/bookcover/book_blank.png")
const BTN_HOVER = preload("res://assets/images/ui/bookshelf/bookcover/book_blank_hover.png")
const BTN_PRESSED = preload("res://assets/images/ui/bookshelf/bookcover/book_blank_pressed.png")
const BTN_GREY_NORMAL = preload("res://assets/images/ui/bookshelf/bookcover/book_blank_grey.png")
const BTN_GREY_HOVER = preload("res://assets/images/ui/bookshelf/bookcover/book_blank_hover_grey.png")
const BTN_GREY_PRESSED = preload("res://assets/images/ui/bookshelf/bookcover/book_blank_pressed_grey.png")

signal locked_album_clicked(album_id: String)
signal download_album_clicked(album_id: String)

@onready var book_icon: Sprite2D = $BookIconNode/BookIcon
@onready var lock_label: Label = $BookIconNode/LockLabel
@onready var status_label: Label = $BookIconNode/StatusLabel
@onready var book_name: Label = $BookName
@onready var dlc_download: TextureRect = $BookIconNode/DLCDownload
@onready var progress_bar: ProgressBar = $BookIconNode/ProgressBar
@onready var progress_label: Label = $BookIconNode/ProgressLabel

var album_id: String = ""

func setup(data: Dictionary) -> void:
	album_id = data.get("id", "")
	book_name.text = data.get("name", "")

	var unlock_result = GameManager.get_album_unlock_status(album_id)
	if not unlock_result.unlocked:
		lock_label.show()
		dlc_download.hide()
		progress_bar.hide()
		progress_label.hide()
		texture_normal = BTN_GREY_NORMAL
		texture_hover = BTN_GREY_HOVER
		texture_pressed = BTN_GREY_PRESSED
		self_modulate = Color(0.4, 0.4, 0.4)
		book_icon.texture = GameManager.get_album_icon_grey(album_id)
		book_icon.modulate = Color(0.4, 0.4, 0.4)
		status_label.text = "未解锁"
		status_label.add_theme_color_override("font_color", Color.WHITE)
		return

	if not AlbumData.is_album_content_available(album_id):
		lock_label.hide()
		dlc_download.show()
		progress_bar.hide()
		progress_label.hide()
		texture_normal = BTN_GREY_NORMAL
		texture_hover = BTN_GREY_HOVER
		texture_pressed = BTN_GREY_PRESSED
		book_icon.texture = GameManager.get_album_icon_grey(album_id)
		if DLCManager.is_downloading() and DLCManager.get_downloading_album_id() == album_id:
			status_label.text = "下载中..."
			status_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
		else:
			status_label.text = "点击下载"
			status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		return

	lock_label.hide()
	dlc_download.hide()
	progress_bar.hide()
	progress_label.hide()
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

func update_download_progress(downloaded: int, total: int) -> void:
	if total <= 0:
		return
	var ratio = float(downloaded) / float(total)
	progress_bar.show()
	progress_label.show()
	progress_bar.value = ratio * 100.0
	var downloaded_mb = float(downloaded) / 1048576.0
	var total_mb = float(total) / 1048576.0
	progress_label.text = "%.1f/%.1f MB" % [downloaded_mb, total_mb]
	status_label.text = "%d%%" % int(ratio * 100)
	status_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	dlc_download.hide()

func show_download_started() -> void:
	progress_bar.show()
	progress_bar.value = 0.0
	progress_label.show()
	progress_label.text = ""
	status_label.text = "0%"
	status_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	dlc_download.hide()

func show_download_failed() -> void:
	progress_bar.hide()
	progress_label.hide()
	status_label.text = "点击下载"
	status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	dlc_download.show()

func _on_book_button_pressed() -> void:
	if album_id == "":
		return
	var unlock_result = GameManager.get_album_unlock_status(album_id)
	if not unlock_result.unlocked:
		locked_album_clicked.emit(album_id)
		return
	if not AlbumData.is_album_content_available(album_id):
		download_album_clicked.emit(album_id)
		return
	AudioManager.play_sfx("click")
	GameManager.pending_album_id = album_id
	get_tree().change_scene_to_file("res://scenes/album_detail.tscn")
