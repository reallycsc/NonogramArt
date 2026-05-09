extends Control

const AlbumDataScript = preload("res://scripts/data/album_data.gd")
const PuzzleDataScript = preload("res://scripts/data/puzzle_data.gd")
const NONOGRAM_BTN_5 = preload("res://assets/images/ui/album/picture_nonogram_5.png")
const NONOGRAM_BTN_5_HOVER = preload("res://assets/images/ui/album/picture_nonogram_5_hover.png")
const NONOGRAM_BTN_5_PRESSED = preload("res://assets/images/ui/album/picture_nonogram_5_pressed.png")
const NONOGRAM_BTN_10 = preload("res://assets/images/ui/album/picture_nonogram_10.png")
const NONOGRAM_BTN_10_HOVER = preload("res://assets/images/ui/album/picture_nonogram_10_hover.png")
const NONOGRAM_BTN_10_PRESSED = preload("res://assets/images/ui/album/picture_nonogram_10_pressed.png")
const NONOGRAM_BTN_15 = preload("res://assets/images/ui/album/picture_nonogram_15.png")
const NONOGRAM_BTN_15_HOVER = preload("res://assets/images/ui/album/picture_nonogram_15_hover.png")
const NONOGRAM_BTN_15_PRESSED = preload("res://assets/images/ui/album/picture_nonogram_15_pressed.png")
const NONOGRAM_BTN_20 = preload("res://assets/images/ui/album/picture_nonogram_20.png")
const NONOGRAM_BTN_20_HOVER = preload("res://assets/images/ui/album/picture_nonogram_20_hover.png")
const NONOGRAM_BTN_20_PRESSED = preload("res://assets/images/ui/album/picture_nonogram_20_pressed.png")
const NONOGRAM_BTN_25 = preload("res://assets/images/ui/album/picture_nonogram_25.png")
const NONOGRAM_BTN_25_HOVER = preload("res://assets/images/ui/album/picture_nonogram_25_hover.png")
const NONOGRAM_BTN_25_PRESSED = preload("res://assets/images/ui/album/picture_nonogram_25_pressed.png")
const NONOGRAM_BTN_LOCKED = preload("res://assets/images/ui/album/picture_nonogram_locked.png")

var current_album_id: String = ""
var current_picture_id: String = ""
var _puzzles: Array = []
var _illustration_image: Image = null
var _pixel_image: Image = null
var _grid_x: int = 1
var _grid_y: int = 1
var _has_valid_source_rects: bool = false
var _region_buttons: Dictionary = {}
var _fade_tween: Tween = null
var _pictures: Array = []
var _current_picture_index: int = 0

const REGION_GAP: float = 0.0

@onready var illustration_area: Control = $VBoxContainer/IllustrationArea
@onready var left_button: TextureButton = $CanvasLayer/LeftButton
@onready var right_button: TextureButton = $CanvasLayer/RightButton
@onready var page_num_label: Label = $PageNumLabel

func _ready() -> void:
	illustration_area.resized.connect(_on_illustration_area_resized)
	left_button.pressed.connect(_on_left_button_pressed)
	right_button.pressed.connect(_on_right_button_pressed)
	if GameManager.pending_album_id != "":
		current_album_id = GameManager.pending_album_id
		GameManager.pending_album_id = ""
		_load_pictures_list()


func setup(album_id: String) -> void:
	current_album_id = album_id
	_load_pictures_list()


func _load_pictures_list() -> void:
	_pictures = AlbumDataScript.load_pictures(current_album_id)
	if _pictures.is_empty():
		return
	
	if GameManager.pending_picture_index >= 0 and GameManager.pending_picture_index < _pictures.size():
		_current_picture_index = GameManager.pending_picture_index
		GameManager.pending_picture_index = -1
	else:
		var saved_index = GameManager.get_saved_picture_index(current_album_id)
		if saved_index >= 0 and saved_index < _pictures.size():
			_current_picture_index = saved_index
		else:
			_current_picture_index = 0
	
	var current_picture = _pictures[_current_picture_index]
	current_picture_id = current_picture.get("id", "")
	_load_picture(current_picture)
	_update_page_navigation()


func _load_picture(picture: Dictionary) -> void:
	_load_puzzles(picture)
	$Title.text = picture.get("title", "")
	var full_text = picture.get("full_text", "")
	$VBoxContainer/AlbumText.text = _get_revealed_text(full_text)
	_build_illustration(picture)


func _get_revealed_text(full_text: String) -> String:
	if not current_picture_id:
		return full_text
	
	if GameManager.is_picture_completed(current_picture_id):
		return full_text
	
	var total_puzzles = _puzzles.size()
	if total_puzzles == 0:
		return full_text
	
	var completed_count = 0
	for puzzle in _puzzles:
		if GameManager.is_puzzle_completed(puzzle.id):
			completed_count += 1
	
	if completed_count == 0:
		return _generate_gibberish(full_text.length(), current_picture_id)
	
	var reveal_ratio = float(completed_count) / float(total_puzzles)
	var reveal_count = max(1, int(full_text.length() * reveal_ratio))
	
	return _reveal_random_chars(full_text, reveal_count, current_picture_id)


func _generate_gibberish(length: int, seed_str: String) -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
	var result = ""
	var seed = _string_to_seed(seed_str)
	var state = seed
	for _i in range(length):
		state = (state * 1103515245 + 12345) & 0x7fffffff
		result += chars[state % chars.length()]
	return result


func _reveal_random_chars(text: String, reveal_count: int, seed_str: String) -> String:
	var length = text.length()
	if length == 0:
		return ""
	
	if reveal_count >= length:
		return text
	
	var seed = _string_to_seed(seed_str)
	var state = seed
	var revealed_indices = []
	while revealed_indices.size() < reveal_count:
		state = (state * 1103515245 + 12345) & 0x7fffffff
		var idx = state % length
		if idx not in revealed_indices:
			revealed_indices.append(idx)
	
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
	var result = ""
	state = seed + 1
	for i in range(length):
		if i in revealed_indices:
			result += text[i]
		else:
			state = (state * 1103515245 + 12345) & 0x7fffffff
			result += chars[state % chars.length()]
	return result


func _string_to_seed(str: String) -> int:
	var hash = 0
	for i in range(str.length()):
		hash = hash * 31 + str.unicode_at(i)
	return abs(hash) & 0x7fffffff


func _load_puzzles(picture: Dictionary) -> void:
	_puzzles.clear()
	var puzzle_ids = picture.get("puzzles", [])
	for pid in puzzle_ids:
		var puzzle = PuzzleDataScript.load_puzzle(pid)
		if puzzle:
			_puzzles.append(puzzle)


func _build_illustration(picture: Dictionary) -> void:
	for child in illustration_area.get_children():
		child.queue_free()
	await _wait_for_free()

	_compute_grid_layout()

	var img_path = picture.get("image", "")
	var has_illustration = false
	if img_path != "" and ResourceLoader.exists(img_path):
		var tex = load(img_path)
		if tex is Texture2D:
			_illustration_image = tex.get_image()
			has_illustration = true

	if not has_illustration:
		_illustration_image = _generate_placeholder_illustration()

	_pixel_image = _load_pixel_image(img_path)

	_create_illustration_display()


func _wait_for_free() -> void:
	while illustration_area.get_child_count() > 0:
		await get_tree().process_frame


func _load_pixel_image(img_path: String) -> Image:
	if img_path == "":
		return null
	var base_path = img_path.get_basename()
	var pixel_path = base_path + "_pixel.png"
	if ResourceLoader.exists(pixel_path):
		var tex = load(pixel_path)
		if tex is Texture2D:
			return tex.get_image()
	return null


func _compute_grid_layout() -> void:
	_has_valid_source_rects = false

	if _puzzles.is_empty():
		_grid_x = 1
		_grid_y = 1
		return

	var ig = _get_image_grid_from_picture()
	if ig.x > 0 and ig.y > 0:
		_grid_x = ig.x
		_grid_y = ig.y
		_has_valid_source_rects = true
		return

	var rects: Array = []
	for puzzle in _puzzles:
		var sr = puzzle.source_rect
		if not sr.has("x") or not sr.has("y") or not sr.has("w") or not sr.has("h"):
			_compute_grid_from_count()
			return
		rects.append(sr)

	if rects.size() <= 1:
		_grid_x = 1
		_grid_y = 1
		if rects.size() == 1 and (rects[0].x > 0 or rects[0].y > 0):
			_has_valid_source_rects = true
		return

	var all_at_origin = true
	for sr in rects:
		if sr.x != 0 or sr.y != 0:
			all_at_origin = false
			break

	if all_at_origin:
		_compute_grid_from_count()
		return

	_has_valid_source_rects = true
	var max_x = 0
	var max_y = 0
	var cell_w = rects[0].w
	var cell_h = rects[0].h
	for sr in rects:
		max_x = max(max_x, sr.x + sr.w)
		max_y = max(max_y, sr.y + sr.h)
		cell_w = min(cell_w, sr.w)
		cell_h = min(cell_h, sr.h)

	if cell_w > 0 and cell_h > 0:
		_grid_x = int(max_x / cell_w)
		_grid_y = int(max_y / cell_h)
	else:
		_compute_grid_from_count()


func _get_image_grid_from_picture() -> Vector2i:
	var picture = AlbumDataScript.get_picture(current_album_id, current_picture_id)
	var ig = picture.get("image_grid", {})
	if ig is Dictionary and ig.has("x") and ig.has("y"):
		return Vector2i(int(ig.x), int(ig.y))
	return Vector2i(0, 0)


func _compute_grid_from_count() -> void:
	var n = _puzzles.size()
	match n:
		0, 1:
			_grid_x = 1
			_grid_y = 1
		2:
			_grid_x = 2
			_grid_y = 1
		3:
			_grid_x = 3
			_grid_y = 1
		4:
			_grid_x = 2
			_grid_y = 2
		5, 6:
			_grid_x = 3
			_grid_y = 2
		7, 8:
			_grid_x = 4
			_grid_y = 2
		_:
			_grid_x = ceili(sqrt(n))
			_grid_y = ceili(float(n) / float(_grid_x))


func _create_illustration_display() -> void:
	_region_buttons.clear()

	if GameManager.is_picture_completed(current_picture_id):
		_create_completed_display()
		return

	var target_size = _calculate_button_size()
	var is_current_picture_locked = _is_current_picture_locked()

	for i in range(_puzzles.size()):
		var puzzle = _puzzles[i]
		var completed = GameManager.is_puzzle_completed(puzzle.id)

		var btn = TextureButton.new()
		btn.name = "RegionBtn_" + str(i)
		btn.stretch_mode = TextureButton.STRETCH_SCALE

		if is_current_picture_locked:
			btn.texture_normal = NONOGRAM_BTN_LOCKED
			btn.texture_hover = NONOGRAM_BTN_LOCKED
			btn.texture_pressed = NONOGRAM_BTN_LOCKED
			btn.disabled = true
		elif not completed:
			_set_btn_tex_nonogram(btn, max(puzzle.rows,puzzle.cols))
		else:
			var region_img = _extract_pixel_region(i, target_size)
			if region_img == null:
				region_img = _extract_hd_region(i, target_size)
			if region_img:
				btn.texture_normal = ImageTexture.create_from_image(region_img)
				btn.texture_hover = _create_hover_texture(region_img)
				btn.texture_pressed = _create_pressed_texture(region_img)
			else:
				_set_btn_tex_nonogram(btn, 5)

		btn.pressed.connect(_on_region_clicked.bind(puzzle))
		illustration_area.add_child(btn)
		_region_buttons[puzzle.id] = btn

	# await get_tree().process_frame # 不要这句代码，否则会闪烁一下
	_update_region_positions()


func _is_current_picture_locked() -> bool:
	if _current_picture_index <= 0:
		return false
	
	var prev_picture = _pictures[_current_picture_index - 1]
	var prev_picture_id = prev_picture.get("id", "")
	return not GameManager.is_picture_completed(prev_picture_id)


func _set_btn_tex_nonogram(btn: TextureButton, grid_num: int) -> void:
	match grid_num:
		5:
			btn.texture_normal = NONOGRAM_BTN_5
			btn.texture_hover = NONOGRAM_BTN_5_HOVER
			btn.texture_pressed = NONOGRAM_BTN_5_PRESSED
		10:
			btn.texture_normal = NONOGRAM_BTN_10
			btn.texture_hover = NONOGRAM_BTN_10_HOVER
			btn.texture_pressed = NONOGRAM_BTN_10_PRESSED
		15:
			btn.texture_normal = NONOGRAM_BTN_15
			btn.texture_hover = NONOGRAM_BTN_15_HOVER
			btn.texture_pressed = NONOGRAM_BTN_15_PRESSED
		20:
			btn.texture_normal = NONOGRAM_BTN_20
			btn.texture_hover = NONOGRAM_BTN_20_HOVER
			btn.texture_pressed = NONOGRAM_BTN_20_PRESSED
		25:
			btn.texture_normal = NONOGRAM_BTN_25
			btn.texture_hover = NONOGRAM_BTN_25_HOVER
			btn.texture_pressed = NONOGRAM_BTN_25_PRESSED	
		_:
			btn.texture_normal = NONOGRAM_BTN_5
			btn.texture_hover = NONOGRAM_BTN_5_HOVER
			btn.texture_pressed = NONOGRAM_BTN_5_PRESSED


func _create_completed_display() -> void:
	var should_animate = GameManager.should_show_animation(current_picture_id)
	
	if _pixel_image and _illustration_image and should_animate:
		var pixel_rect = TextureRect.new()
		pixel_rect.name = "PixelArtRect"
		pixel_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		pixel_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pixel_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pixel_rect.texture = ImageTexture.create_from_image(_pixel_image)
		illustration_area.add_child(pixel_rect)

		var hd_rect = TextureRect.new()
		hd_rect.name = "HDImageRect"
		hd_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		hd_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hd_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hd_rect.texture = ImageTexture.create_from_image(_illustration_image)
		hd_rect.modulate.a = 0.0
		illustration_area.add_child(hd_rect)

		if _fade_tween:
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(hd_rect, "modulate:a", 1.0, 1.5)
		_fade_tween.parallel().tween_property(pixel_rect, "modulate:a", 0.0, 1.5)
		
		_fade_tween.finished.connect(_on_animation_finished)
	elif _illustration_image:
		var hd_rect = TextureRect.new()
		hd_rect.name = "HDImageRect"
		hd_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		hd_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hd_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hd_rect.texture = ImageTexture.create_from_image(_illustration_image)
		illustration_area.add_child(hd_rect)
	elif _pixel_image:
		var pixel_rect = TextureRect.new()
		pixel_rect.name = "PixelArtRect"
		pixel_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		pixel_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pixel_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pixel_rect.texture = ImageTexture.create_from_image(_pixel_image)
		illustration_area.add_child(pixel_rect)


func _on_animation_finished() -> void:
	GameManager.mark_animation_shown(current_picture_id)


func _extract_pixel_region(index: int, target_size: Vector2 = Vector2.ZERO) -> Image:
	if not _pixel_image:
		return null

	var img_w = _pixel_image.get_width()
	var img_h = _pixel_image.get_height()
	var region = _get_region_pixel_rect(index, img_w, img_h)

	var ri = Rect2i(int(region.position.x), int(region.position.y), int(region.size.x), int(region.size.y))
	ri = ri.intersection(Rect2i(0, 0, img_w, img_h))

	if ri.size.x <= 0 or ri.size.y <= 0:
		return null

	var region_img = _pixel_image.get_region(ri)

	if target_size.x > 0 and target_size.y > 0:
		region_img.resize(int(target_size.x), int(target_size.y), Image.INTERPOLATE_NEAREST)

	return region_img


func _extract_hd_region(index: int, target_size: Vector2 = Vector2.ZERO) -> Image:
	if not _illustration_image:
		return null

	var img_w = _illustration_image.get_width()
	var img_h = _illustration_image.get_height()
	var region = _get_region_pixel_rect(index, img_w, img_h)

	var ri = Rect2i(int(region.position.x), int(region.position.y), int(region.size.x), int(region.size.y))
	ri = ri.intersection(Rect2i(0, 0, img_w, img_h))

	if ri.size.x <= 0 or ri.size.y <= 0:
		return null

	var region_img = _illustration_image.get_region(ri)

	if target_size.x > 0 and target_size.y > 0:
		region_img.resize(int(target_size.x), int(target_size.y), Image.INTERPOLATE_NEAREST)

	return region_img


func _create_hover_texture(img: Image) -> ImageTexture:
	var hover = img.duplicate()
	if hover.get_format() != Image.FORMAT_RGBA8:
		hover.convert(Image.FORMAT_RGBA8)
	
	for y in range(hover.get_height()):
		for x in range(hover.get_width()):
			var color = hover.get_pixel(x, y)
			var new_color = Color(
				min(color.r + 0.2, 1.0),
				min(color.g + 0.2, 1.0),
				min(color.b + 0.2, 1.0),
				color.a
			)
			hover.set_pixel(x, y, new_color)
	
	return ImageTexture.create_from_image(hover)


func _create_pressed_texture(img: Image) -> ImageTexture:
	var pressed = img.duplicate()
	if pressed.get_format() != Image.FORMAT_RGBA8:
		pressed.convert(Image.FORMAT_RGBA8)
	
	for y in range(pressed.get_height()):
		for x in range(pressed.get_width()):
			var color = pressed.get_pixel(x, y)
			var new_color = Color(
				max(color.r - 0.2, 0.0),
				max(color.g - 0.2, 0.0),
				max(color.b - 0.2, 0.0),
				color.a
			)
			pressed.set_pixel(x, y, new_color)
	
	return ImageTexture.create_from_image(pressed)


func _calculate_button_size() -> Vector2:
	if _puzzles.is_empty():
		return Vector2.ZERO

	var area_size = illustration_area.size
	if area_size.x <= 0 or area_size.y <= 0:
		return Vector2(160, 160)

	var ref_w: float
	var ref_h: float
	if _illustration_image and _illustration_image.get_width() > 0 and _illustration_image.get_height() > 0:
		ref_w = _illustration_image.get_width()
		ref_h = _illustration_image.get_height()
	else:
		ref_w = _grid_x * 160.0
		ref_h = _grid_y * 160.0

	var total_gap_x = REGION_GAP * max(_grid_x - 1, 0)
	var total_gap_y = REGION_GAP * max(_grid_y - 1, 0)

	var img_aspect = ref_w / ref_h
	var area_aspect = (area_size.x - total_gap_x) / (area_size.y - total_gap_y)

	var display_w: float
	var display_h: float

	if img_aspect > area_aspect:
		display_w = area_size.x - total_gap_x
		display_h = display_w / img_aspect
	else:
		display_h = area_size.y - total_gap_y
		display_w = display_h * img_aspect

	var cell_w = display_w / _grid_x
	var cell_h = display_h / _grid_y

	return Vector2(cell_w, cell_h)


func _get_region_pixel_rect(index: int, img_w: int, img_h: int) -> Rect2:
	if _has_valid_source_rects:
		var sr = _puzzles[index].source_rect
		if sr.has("x") and sr.has("y") and sr.has("w") and sr.has("h"):
			return Rect2(sr.x, sr.y, sr.w, sr.h)

	var col = index % _grid_x
	var row = int(float(index) / _grid_x)
	var cell_w = float(img_w) / _grid_x
	var cell_h = float(img_h) / _grid_y
	return Rect2(col * cell_w, row * cell_h, cell_w, cell_h)


func _update_region_positions() -> void:
	if _puzzles.is_empty():
		return

	var area_size = illustration_area.size
	if area_size.x <= 0 or area_size.y <= 0:
		return

	var ref_w: float
	var ref_h: float
	if _illustration_image and _illustration_image.get_width() > 0 and _illustration_image.get_height() > 0:
		ref_w = _illustration_image.get_width()
		ref_h = _illustration_image.get_height()
	else:
		ref_w = _grid_x * 160.0
		ref_h = _grid_y * 160.0

	var total_gap_x = REGION_GAP * max(_grid_x - 1, 0)
	var total_gap_y = REGION_GAP * max(_grid_y - 1, 0)

	var img_aspect = ref_w / ref_h
	var area_aspect = (area_size.x - total_gap_x) / (area_size.y - total_gap_y)

	var display_w: float
	var display_h: float
	var offset_x: float = 0
	var offset_y: float = 0

	if img_aspect > area_aspect:
		display_w = area_size.x - total_gap_x
		display_h = display_w / img_aspect
		offset_y = (area_size.y - total_gap_y - display_h) / 2
	else:
		display_h = area_size.y - total_gap_y
		display_w = display_h * img_aspect
		offset_x = (area_size.x - total_gap_x - display_w) / 2

	var cell_w = display_w / _grid_x
	var cell_h = display_h / _grid_y

	for i in range(_puzzles.size()):
		var puzzle = _puzzles[i]
		var btn = _region_buttons.get(puzzle.id) as TextureButton
		if not btn:
			continue

		var col = i % _grid_x
		var row = int(float(i) / _grid_x)

		btn.position = Vector2(
			offset_x + col * (cell_w + REGION_GAP),
			offset_y + row * (cell_h + REGION_GAP)
		)
		btn.size = Vector2(cell_w, cell_h)


func _on_illustration_area_resized() -> void:
	_update_region_positions()


func _on_region_clicked(puzzle: PuzzleData) -> void:
	GameManager.pending_album_id = current_album_id
	GameManager.pending_picture_id = current_picture_id
	GameManager.pending_picture_index = _current_picture_index
	GameManager.pending_puzzle_id = puzzle.id
	get_tree().change_scene_to_file("res://scenes/nonogram_scene.tscn")


func _generate_placeholder_illustration() -> Image:
	var base_w = 640
	var base_h = 360

	if _grid_x > 0 and _grid_y > 0:
		var aspect = float(_grid_x) / float(_grid_y)
		if aspect >= 1:
			base_w = 640
			base_h = int(640.0 / aspect)
		else:
			base_h = 480
			base_w = int(480.0 * aspect)

	var img = Image.create(base_w, base_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))
	img.fill_rect(Rect2i(0, 0, base_w, int(base_h * 0.4)), Color(0.75, 0.85, 0.95, 0.4))
	img.fill_rect(Rect2i(0, int(base_h * 0.7), base_w, int(base_h * 0.3)), Color(0.6, 0.5, 0.35, 0.3))

	return img


func _on_back_pressed() -> void:
	GameManager.save_picture_index(current_album_id, _current_picture_index)
	GameManager.pending_bookshelf_id = ""
	var album = AlbumDataScript.get_album(current_album_id)
	if not album.is_empty():
		GameManager.pending_bookshelf_id = album.get("bookshelf_id", "")
	get_tree().change_scene_to_file("res://scenes/book_shelf.tscn")


func _on_left_button_pressed() -> void:
	if _current_picture_index > 0:
		_current_picture_index -= 1
		var picture = _pictures[_current_picture_index]
		current_picture_id = picture.get("id", "")
		_load_picture(picture)
		_update_page_navigation()


func _on_right_button_pressed() -> void:
	if _current_picture_index < _pictures.size() - 1:
		_current_picture_index += 1
		var picture = _pictures[_current_picture_index]
		current_picture_id = picture.get("id", "")
		_load_picture(picture)
		_update_page_navigation()


func _update_page_navigation() -> void:
	left_button.visible = _current_picture_index > 0
	right_button.visible = _current_picture_index < _pictures.size() - 1
	page_num_label.text = "%d/%d" % [_current_picture_index + 1, _pictures.size()]
