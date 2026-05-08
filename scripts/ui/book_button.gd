extends TextureButton

@onready var book_icon: Sprite2D = $BookIconNode/BookIcon
@onready var lock_label: Label = $BookIconNode/LockLabel
@onready var status_label: Label = $BookIconNode/StatusLabel
@onready var book_name: Label = $BookName

var album_id: String = ""

func setup(data: Dictionary) -> void:
	album_id = data.get("id", "")
	book_icon.texture = GameManager.get_album_icon(album_id)
	book_name.text = data.get("name", "")

	var unlock_result = GameManager.get_album_unlock_status(album_id)
	if not unlock_result.unlocked:
		lock_label.show()
		modulate = Color(0.4, 0.4, 0.4)
		status_label.text = "未解锁"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		disabled = true
	else:
		disabled = false
		lock_label.hide()
		var completion = GameManager.get_album_completion(album_id)
		if completion >= 1.0:
			status_label.text = "已完成"
			status_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2))
		else:
			status_label.text = "%d%%" % int(completion * 100)
			status_label.add_theme_color_override("font_color", Color(0.76, 0.23, 0.13))


func _on_book_button_pressed() -> void:
	if album_id == "":
		return
	var unlock_result = GameManager.get_album_unlock_status(album_id)
	if not unlock_result.unlocked:
		return
	GameManager.pending_album_id = album_id
	get_tree().change_scene_to_file("res://scenes/album_detail.tscn")
